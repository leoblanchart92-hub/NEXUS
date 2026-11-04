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

/// Fait le lien entre l'interface, la mémoire de Nexus et son vrai cerveau
/// neuronal (un modèle exécuté sur le téléphone).
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

  NexusBrain? _brain;
  bool _loading = true;
  bool _thinking = false;
  bool _disposed = false;
  bool _checkingUpdate = false;
  String _partial = '';
  UpdateCheck? _lastUpdateCheck;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool get isLoading => _loading;
  bool get isThinking => _thinking;
  bool get hasNexus => _brain != null;
  NexusState? get state => _brain?.state;
  String get name => _brain?.state.name ?? 'Nexus';
  bool get voiceEnabled => _brain?.state.voiceEnabled ?? false;
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
  String get persona => _brain?.state.persona ?? '';

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
      final brain = NexusBrain(state: saved);
      _brain = brain;
      _messages.add(
        ChatMessage(
          text: brain.greeting(),
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
    final brain = NexusBrain(state: state);
    _brain = brain;
    _messages
      ..clear()
      ..add(
        ChatMessage(
          text: brain.birthCry,
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
    final brain = _brain;
    final text = raw.trim();
    if (brain == null || text.isEmpty || _thinking) return;

    // Le contexte est construit avant d'ajouter la phrase, pour ne pas
    // la lui montrer deux fois.
    final context = buildPromptContext(
      brain.state,
      recentTurns: _recentTurns(),
    );

    _messages.add(ChatMessage(text: text, fromNexus: false, at: DateTime.now()));
    _thinking = true;
    _partial = '';
    _notify();

    // Le moteur à mots ne parle plus : il tient seulement la croissance,
    // le vocabulaire et les faits appris (xp, mémoire, besoins).
    final growth = brain.respond(text);

    var replyText = growth.text;
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
        replyText = growth.text;
        _messages.add(
          ChatMessage.system(
            'Le cerveau neuronal n\'a pas répondu (${_llm.error ?? error}).',
          ),
        );
      }
    }

    _partial = '';
    _thinking = false;
    _messages.add(
      ChatMessage(text: replyText, fromNexus: true, at: DateTime.now()),
    );
    if (growth.stageUp) {
      _messages.add(
        ChatMessage.system(
          'Nexus grandit : ${growth.stage.label} ${growth.stage.emoji}',
        ),
      );
    }
    _notify();

    if (brain.state.voiceEnabled) {
      await _tts?.speak(replyText);
    }
    await _store.save(brain.state);
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

  /// Lui apprend un mot et sa définition.
  Future<LessonResult?> teach(String word, String definition) async {
    final brain = _brain;
    if (brain == null || word.trim().isEmpty || definition.trim().isEmpty) {
      return null;
    }

    final result = brain.teach(word, definition);
    _messages.add(
      ChatMessage(
        text: 'J\'ai retenu : ${word.trim()} — ${definition.trim()}',
        fromNexus: true,
        at: DateTime.now(),
      ),
    );
    if (result.stageUp) {
      _messages.add(
        ChatMessage.system(
          'Nexus grandit : ${brain.state.stage.label} '
          '${brain.state.stage.emoji}',
        ),
      );
    }
    _notify();

    if (brain.state.voiceEnabled) {
      await _tts?.speak(result.reply);
    }
    await _store.save(brain.state);
    return result;
  }

  /// Change les règles de personnalité écrites par son humain.
  Future<void> setPersona(String rules) async {
    final brain = _brain;
    if (brain == null) return;

    brain.state.persona = rules.trim();
    _notify();
    await _store.save(brain.state);
  }

  /// Allume ou éteint la voix de Nexus.
  Future<void> setVoice(bool enabled) async {
    final brain = _brain;
    if (brain == null) return;

    brain.state.voiceEnabled = enabled;
    _notify();

    if (enabled) {
      await _tts?.speak('Ma voix est allumée.');
    } else {
      await _tts?.stop();
    }
    await _store.save(brain.state);
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

  /// Efface tout et le fait renaître (le cerveau reste installé).
  Future<void> reset() async {
    await _store.wipe();
    _brain = null;
    _messages.clear();
    _partial = '';
    _lastUpdateCheck = null;
    _notify();
  }
}
