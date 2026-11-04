import 'package:flutter/foundation.dart';
import 'package:nexus_core/nexus_core.dart';

import '../data/nexus_store.dart';

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
  NexusController(this._store);

  final NexusStore _store;
  NexusBrain? _brain;
  bool _loading = true;
  bool _thinking = false;
  bool _disposed = false;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool get isLoading => _loading;
  bool get isThinking => _thinking;
  bool get hasNexus => _brain != null;
  NexusState? get state => _brain?.state;
  String get name => _brain?.state.name ?? 'Nexus';
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  @override
  void dispose() {
    _disposed = true;
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
        ChatMessage.system('Nexus grandit : ${reply.stage.label} ${reply.stage.emoji}'),
      );
    }
    _thinking = false;
    _notify();
    await _store.save(brain.state);
  }

  /// Efface tout et le fait renaître.
  Future<void> reset() async {
    await _store.wipe();
    _brain = null;
    _messages.clear();
    _notify();
  }
}
