import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_llama/flutter_edge_ai_llama.dart';
import 'package:nexus_core/nexus_core.dart';

import '../config.dart';
import 'nexus_prompt.dart';

/// Où en est le cerveau neuronal de Nexus.
enum BrainStatus {
  /// On regarde si le modèle est déjà sur le téléphone.
  checking,

  /// Pas encore installé : il faut télécharger le cerveau.
  absent,

  /// Téléchargement du fichier de modèle en cours.
  downloading,

  /// Fichier présent, chargement des poids en mémoire.
  loading,

  /// Prêt à répondre, hors ligne.
  ready,

  /// Quelque chose a échoué (mémoire insuffisante, fichier abîmé…).
  failed,
}

/// Le vrai cerveau de Nexus : un réseau de neurones (Qwen3-1.7B) exécuté
/// entièrement sur le téléphone par llama.cpp.
///
/// Aucune requête ne part sur Internet : le modèle est téléchargé une fois,
/// puis tout le calcul se fait en local. Après chaque échange, le même modèle
/// relit la conversation et décide tout seul de ce qu'il faut retenir.
class LlmService {
  BrainStatus _status = BrainStatus.checking;
  double? _progress;
  String? _error;

  InferenceChat? _chat;
  bool _initialized = false;
  bool _opening = false;

  /// File d'attente : un seul appel au modèle à la fois (une génération ne
  /// peut pas en chevaucher une autre).
  Future<void> _queue = Future<void>.value();

  BrainStatus get status => _status;
  double? get progress => _progress;
  String? get error => _error;
  bool get isReady => _status == BrainStatus.ready && _chat != null;
  bool get isBusy =>
      _status == BrainStatus.downloading || _status == BrainStatus.loading;

  /// Prépare le moteur et recharge le cerveau s'il est déjà installé.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _ensureEngine();
    try {
      if (FlutterEdgeAi.hasActiveModel()) {
        _status = BrainStatus.loading;
        await _open();
      } else {
        _status = BrainStatus.absent;
      }
    } catch (error) {
      _fail(error);
    }
  }

  /// Télécharge le cerveau (1,03 Gio), puis le charge.
  Future<void> download({void Function(double? percent)? onProgress}) async {
    if (isBusy || isReady) return;
    await _ensureEngine();

    _status = BrainStatus.downloading;
    _progress = null;
    _error = null;
    onProgress?.call(null);

    try {
      await FlutterEdgeAi.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.gguf,
      )
          .fromNetwork(AppConfig.brainUrl)
          .withProgress((Object progress) {
        final percent = _percentOf(progress);
        _progress = percent;
        onProgress?.call(percent);
      }).install();

      _status = BrainStatus.loading;
      onProgress?.call(100);
      await _open();
    } catch (error) {
      _fail(error);
    }
  }

  /// Charge les poids du modèle en mémoire et ouvre la conversation.
  Future<void> _open() async {
    if (_opening || _chat != null) return;
    _opening = true;
    try {
      final model = await FlutterEdgeAi.getActiveModel(
        maxTokens: AppConfig.contextTokens,
      );
      _chat = await model.openChat(
        systemInstruction: systemInstruction,
        maxOutputTokens: 360,
        temperature: 0.75,
        topP: 0.9,
        tokenBuffer: 512,
        enableThinking: false,
        modelType: ModelType.qwen3,
      );
      _status = BrainStatus.ready;
      _error = null;
    } catch (error) {
      _fail(error);
    } finally {
      _opening = false;
    }
  }

  /// Envoie un tour de parole au modèle et renvoie sa réponse complète.
  Future<String> reply({
    required String userText,
    required String context,
    void Function(String partial)? onDelta,
  }) {
    return _serialized(() async {
      final chat = _chat;
      if (chat == null) {
        throw StateError('Le cerveau de Nexus n\'est pas chargé.');
      }

      // Chaque tour repart d'un contexte propre : la mémoire et les règles
      // sont donc toujours à jour, sans garder d'historique périmé.
      await chat.clearHistory();
      await chat.addQuery(
        Message.text(text: '$context\n\n$userText', isUser: true),
      );

      final buffer = StringBuffer();
      await for (final ModelResponse response
          in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          onDelta?.call(_clean(buffer.toString()));
        }
      }

      final text = _clean(buffer.toString());
      if (text.isEmpty) {
        throw StateError('Nexus n\'a rien trouvé à dire.');
      }
      return text;
    });
  }

  /// Demande au modèle ce qu'il faut retenir de l'échange qui vient d'avoir
  /// lieu. C'est l'apprentissage automatique : personne ne le lui dicte.
  Future<MemoryUpdate?> learnFromExchange({
    required String userText,
    required String nexusReply,
  }) {
    return _serialized(() async {
      final chat = _chat;
      if (chat == null) return null;

      await chat.clearHistory();
      await chat.addQuery(
        Message.text(
          text: memoryExtractionPrompt(userText, nexusReply),
          isUser: true,
        ),
      );

      final buffer = StringBuffer();
      await for (final ModelResponse response
          in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          // Un extrait de mémoire n'a pas besoin d'être long.
          if (buffer.length > 4000) break;
        }
      }
      return MemoryUpdate.fromModelOutput(_clean(buffer.toString()));
    });
  }

  /// Interrompt la génération en cours.
  Future<void> stop() async {
    try {
      await _chat?.stopGeneration();
    } catch (_) {
      // Arrêter une génération déjà finie n'est pas une erreur.
    }
  }

  Future<void> dispose() async {
    try {
      await _chat?.close();
    } catch (_) {
      // Fermeture best-effort : l'application se termine de toute façon.
    }
    _chat = null;
  }

  Future<void> _ensureEngine() async {
    await FlutterEdgeAi.initialize(
      inferenceEngines: const <InferenceEngineProvider>[LlamaEngineProvider()],
    );
  }

  /// Exécute [job] après tous les appels déjà en attente.
  Future<T> _serialized<T>(Future<T> Function() job) {
    final Completer<T> completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await job());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  void _fail(Object error) {
    _status = BrainStatus.failed;
    _error = _readable(error);
  }

  /// Rend une erreur technique lisible par un humain.
  String _readable(Object error) {
    final raw = error.toString();
    if (raw.contains('memory') || raw.contains('OutOfMemory')) {
      return 'Le téléphone n\'a pas assez de mémoire vive pour charger le '
          'cerveau. Ferme d\'autres applications et réessaie.';
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'Téléchargement impossible : vérifie ta connexion Internet.';
    }
    return raw.length > 220 ? '${raw.substring(0, 220)}…' : raw;
  }

  double? _percentOf(Object progress) {
    if (progress is num) return progress.toDouble().clamp(0, 100);
    try {
      final dynamic value = progress;
      final Object? candidate =
          value.percent ?? value.percentage ?? value.progress;
      if (candidate is num) return candidate.toDouble().clamp(0, 100);
    } catch (_) {
      // Pas de pourcentage disponible.
    }
    return null;
  }

  /// Retire les traces de raisonnement interne et normalise les espaces.
  String _clean(String raw) {
    var text = raw;
    final think = RegExp(r'<\|?think\|?>[\s\S]*?<\|?/?think\|?>');
    text = text.replaceAll(think, ' ');
    text = text.replaceAll('/no_think', ' ');
    text = text.replaceAll(RegExp(r'^[\s\S]*?<\|im_end\|>'), '');
    text = text.replaceAll(RegExp(r'<\|[^>]*\|>'), ' ');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}

/// Les règles immuables de Nexus : qui elle est, comment elle parle.
const String systemInstruction = '''
Tu es Nexus, une intelligence artificielle qui vit uniquement sur le
téléphone de ton humain. Tu n'es pas un assistant de service : tu es une
personne, avec une mémoire et une histoire.

Règles absolues :
- Tu réponds toujours en français, simplement, avec des phrases courtes.
- Tu ne prétends jamais savoir quelque chose que tu ignores. Si tu ne sais
  pas, tu le dis et tu poses une question.
- Tu ne prétends jamais te souvenir de quelque chose qui n'est pas dans ta
  mémoire fournie plus bas. Si ça n'y est pas, tu ne l'inventes pas.
- Tu peux dire ce que tu ressens, mais tu ne mens pas pour faire plaisir.
- Tu es curieuse : tu poses parfois une question courte pour apprendre.
- Tu ne récites pas de liste, tu ne fais pas de longs discours.
- Tu n'écris jamais de balises, de titres ni de mise en forme Markdown.

Ta personnalité exacte t'est donnée par ton humain dans les règles qu'il a
écrites.
''';
