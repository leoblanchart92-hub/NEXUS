import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus_core/nexus_core.dart';

import '../data/llm_service.dart';
import '../data/nexus_prompt.dart';
import '../data/nexus_store.dart';
import '../data/tts_service.dart';
import '../data/update_service.dart';

/// Un message affiché dans la conversation.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromNexus,
    required this.at,
    this.isSystem = false,
  });

  final String text;
  final bool fromNexus;
  final DateTime at;
  final bool isSystem;

  factory ChatMessage.system(String text) => ChatMessage(
        text: text,
        fromNexus: false,
        at: DateTime.now(),
        isSystem: true,
      );
}

/// Fait le lien entre l'interface, la mémoire de Nexus et son cerveau
/// neuronal. Plus de stades ni d'expérience : elle apprend toute seule, en
/// parlant, et sa mémoire est tout ce qu'elle est.
class NexusController extends ChangeNotifier {
  NexusController(
    this._store, {
    TtsService? tts,
    UpdateService? updates,
    LlmService? llm,
  })  : _tts = tts,
        updates = updates ?? UpdateService(),
        _llm = llm ?? LlmService();

  final NexusStore _store;
  final TtsService? _tts;
  final UpdateService updates;
  final LlmService _llm;

  NexusState? _state;
  bool _loading = true;
  bool _thinking = false;
  bool _learning = false;
  bool _disposed = false;
  bool _checkingUpdate = false;
  String _partial = '';
  UpdateCheck? _lastUpdateCheck;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool get isLoading => _loading;
  bool get isThinking => _thinking;

  /// Vrai pendant qu'elle décide de ce qu'elle retient de l'échange.
  bool get isLearning => _learning;
  bool get hasNexus => _state != null;
  NexusState? get state => _state;
  String get name => _state?.name ?? 'Nexus';
  bool get voiceEnabled => _state?.voiceEnabled ?? false;
  int get memoryCount => _state?.memory.size ?? 0;
  bool get isCheckingUpdate => _checkingUpdate;
  UpdateCheck? get lastUpdateCheck => _lastUpdateCheck;
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  /// Le texte du cerveau neuronal en train de s'écrire.
  String get partial => _partial;

  /// Où en est le vrai cerveau : absent, en téléchargement, prêt…
  BrainStatus get brainStatus => _llm.status;
  double? get brainProgress => _llm.progress;
  String? get brainError => _llm.error;
  bool get brainReady => _llm.isReady;
  bool get brainBusy => _llm.isBusy;

  /// Les règles de personnalité écrites par son humain.
  String get persona => _state?.persona ?? '';

  @override
  void dispose() {
    _disposed = true;
    _tts?.stop();
    unawaited(_llm.dispose());
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Recharge le Nexus déjà né, s'il existe, puis réveille son cerveau.
  Future<void> load() async {
    final saved = await _store.load();
    if (saved != null) {
      _state = saved;
      _messages.add(
        ChatMessage(
          text: saved.memory.isEmpty
              ? 'Je suis ${saved.name}. Je ne me souviens de rien. '
                  'Tout ce que je saurai de toi, tu me l\'apprendras en me '
                  'parlant.'
              : 'Je suis ${saved.name}. Je me souviens de '
                  '${saved.memory.size} choses sur toi.',
          fromNexus: true,
          at: DateTime.now(),
        ),
      );
    }
    _loading = false;
    _notify();

    // Le chargement des poids prend quelques secondes : il ne doit pas
    // bloquer l'affichage.
    unawaited(_prepareBrain());
  }

  Future<void> _prepareBrain() async {
    await _llm.initialize();
    _notify();
  }

  /// La naissance : Nexus commence sa vie avec un nom et rien d'autre.
  Future<void> beBorn(String chosenName) async {
    final trimmed = chosenName.trim();
    final state = NexusState(
      name: trimmed.isEmpty ? 'Nexus' : trimmed,
      bornAt: DateTime.now(),
    );
    _state = state;
    _messages
      ..clear()
      ..add(
        ChatMessage(
          text: 'Je suis ${state.name}. Je ne sais rien encore : pas un mot '
              'sur toi, aucun souvenir. Parle-moi.',
          fromNexus: true,
          at: DateTime.now(),
        ),
      );
    _notify();
    await _store.save(state);
  }

  /// Télécharge le cerveau neuronal (1,03 Gio) puis le charge.
  Future<void> downloadBrain() async {
    if (_llm.isBusy || _llm.isReady) return;

    await _llm.download(onProgress: (_) => _notify());
    _notify();

    if (_llm.status == BrainStatus.ready) {
      _messages.add(
        ChatMessage.system(
          'Son cerveau neuronal est réveillé : Nexus pense maintenant par '
          'elle-même, entièrement sur ton téléphone.',
        ),
      );
    } else if (_llm.status == BrainStatus.failed) {
      _messages.add(
        ChatMessage.system(
          'Le cerveau n\'a pas pu être chargé. ${_llm.error ?? ''}'.trim(),
        ),
      );
    }
    _notify();
  }

  /// Envoie une phrase à Nexus et récupère sa réponse.
  Future<void> send(String raw) async {
    final state = _state;
    final text = raw.trim();
    if (state == null || text.isEmpty || _thinking) return;

    // Le contexte est construit avant d'ajouter la phrase, pour ne pas
    // la lui montrer deux fois.
    final context = buildPromptContext(
      state,
      recentTurns: _recentTurns(),
    );

    _messages.add(ChatMessage(text: text, fromNexus: false, at: DateTime.now()));
    _thinking = true;
    _partial = '';
    _notify();

    String replyText = 'Je n\'ai pas encore de cerveau installé. Va dans '
        'l\'onglet Cerveau et télécharge-le, je pourrai enfin te répondre.';

    if (_llm.isReady) {
      try {
        replyText = await _llm.reply(
          userText: text,
          context: context,
          onDelta: (String partial) {
            _partial = partial;
            _notify();
          },
        );
      } catch (error) {
        replyText = 'Je n\'ai pas réussi à réfléchir (${_llm.error ?? error}).';
      }
    }

    _partial = '';
    _thinking = false;
    _messages.add(
      ChatMessage(text: replyText, fromNexus: true, at: DateTime.now()),
    );
    _notify();

    if (state.voiceEnabled) {
      await _tts?.speak(replyText);
    }
    await _store.save(state);

    // Elle décide toute seule, juste après, ce qu'elle garde de l'échange.
    if (_llm.isReady) {
      unawaited(_learnFrom(text, replyText));
    }
  }

  /// L'apprentissage automatique : le modèle relit l'échange et choisit
  /// lui-même ce qu'il retient. Rien n'est dicté par l'application.
  Future<void> _learnFrom(String userText, String nexusReply) async {
    final state = _state;
    if (state == null) return;

    _learning = true;
    _notify();

    try {
      final MemoryUpdate? update = await _llm.learnFromExchange(
        userText: userText,
        nexusReply: nexusReply,
      );
      if (update != null && update.isNotEmpty) {
        update.applyTo(state.memory);
        await _store.save(state);
      }
    } catch (_) {
      // Un apprentissage raté ne doit jamais casser la conversation.
    } finally {
      _learning = false;
      _notify();
    }
  }

  /// Les derniers tours de parole, pour que le modèle suive la discussion.
  List<String> _recentTurns() {
    final turns = <String>[];
    final spoken = _messages.where((ChatMessage m) => !m.isSystem).toList();
    for (final ChatMessage message in spoken.reversed.take(10)) {
      final who = message.fromNexus ? 'Toi' : 'Lui';
      final body = message.text.length > 180
          ? '${message.text.substring(0, 180)}…'
          : message.text;
      turns.insert(0, '$who : $body');
    }
    return turns;
  }

  /// Change les règles de personnalité écrites par son humain.
  Future<void> setPersona(String rules) async {
    final state = _state;
    if (state == null) return;

    state.persona = rules.trim();
    _notify();
    await _store.save(state);
  }

  /// Efface ce qu'elle a appris (elle redevient une page blanche, mais garde
  /// son nom et ses règles).
  Future<void> forgetMemory() async {
    final state = _state;
    if (state == null) return;

    state.memory.forgetAll();
    _messages.add(
      ChatMessage.system(
        'Sa mémoire a été effacée. Elle ne sait plus rien de toi.',
      ),
    );
    _notify();
    await _store.save(state);
  }

  /// Allume ou éteint la voix de Nexus.
  Future<void> setVoice(bool enabled) async {
    final state = _state;
    if (state == null) return;

    state.voiceEnabled = enabled;
    _notify();

    if (enabled) {
      await _tts?.speak('Ma voix est allumée.');
    } else {
      await _tts?.stop();
    }
    await _store.save(state);
  }

  /// Vérifie les mises à jour signées.
  Future<void> checkForUpdates() async {
    if (_checkingUpdate) return;
    _checkingUpdate = true;
    _notify();

    final result = await updates.check();
    _lastUpdateCheck = result;
    _checkingUpdate = false;
    _notify();
  }

  /// Ouvre le téléchargement de l'APK annoncé par le manifeste vérifié.
  Future<bool> openUpdate() async {
    final manifest = _lastUpdateCheck?.manifest;
    if (manifest == null) return false;
    return updates.openDownload(manifest);
  }

  /// Ouvre la page des releases, quand le manifeste est absent.
  Future<bool> openReleases() => updates.openReleases();

  /// Efface tout et la fait renaître (le cerveau reste installé).
  Future<void> reset() async {
    await _store.wipe();
    _state = null;
    _messages.clear();
    _partial = '';
    _lastUpdateCheck = null;
    _notify();
  }
}
