import 'package:flutter/foundation.dart';
import 'package:nexus_core/nexus_core.dart';

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

/// Fait le lien entre l'interface et le cerveau de Nexus.
class NexusController extends ChangeNotifier {
  NexusController(this._store, {TtsService? tts, UpdateService? updates})
      : _tts = tts,
        updates = updates ?? UpdateService();

  final NexusStore _store;
  final TtsService? _tts;
  final UpdateService updates;

  NexusBrain? _brain;
  bool _loading = true;
  bool _thinking = false;
  bool _disposed = false;
  bool _checkingUpdate = false;
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

  @override
  void dispose() {
    _disposed = true;
    _tts?.stop();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Recharge le Nexus déjà né, s'il existe.
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

  /// Envoie une phrase à Nexus et récupère sa réponse.
  Future<void> send(String raw) async {
    final brain = _brain;
    final text = raw.trim();
    if (brain == null || text.isEmpty || _thinking) return;

    _messages.add(ChatMessage(text: text, fromNexus: false, at: DateTime.now()));
    _thinking = true;
    _notify();

    // Une petite hésitation : il réfléchit vraiment, lui.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (_disposed) return;

    final reply = brain.respond(text);
    _messages.add(
      ChatMessage(text: reply.text, fromNexus: true, at: DateTime.now()),
    );
    if (reply.stageUp) {
      _messages.add(
        ChatMessage.system(
          'Nexus grandit : ${reply.stage.label} ${reply.stage.emoji}',
        ),
      );
    }
    _thinking = false;
    _notify();

    if (brain.state.voiceEnabled) {
      await _tts?.speak(reply.text);
    }
    await _store.save(brain.state);
  }

  /// Lui apprend un mot et sa définition.
  Future<LessonResult?> teach(String word, String definition) async {
    final brain = _brain;
    if (brain == null || word.trim().isEmpty || definition.trim().isEmpty) {
      return null;
    }

    final result = brain.teach(word, definition);
    _messages.add(
      ChatMessage(text: result.reply, fromNexus: true, at: DateTime.now()),
    );
    if (result.stageUp) {
      _messages.add(
        ChatMessage.system(
          'Nexus grandit : ${brain.state.stage.label} ${brain.state.stage.emoji}',
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

  /// Efface tout et le fait renaître.
  Future<void> reset() async {
    await _store.wipe();
    _brain = null;
    _messages.clear();
    _lastUpdateCheck = null;
    _notify();
  }
}
