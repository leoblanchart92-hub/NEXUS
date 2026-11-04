import 'package:flutter/material.dart';
import 'package:nexus_core/nexus_core.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';
import 'widgets/message_bubble.dart';

/// L'onglet de conversation.
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.controller});

  final NexusController controller;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    widget.controller.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.controller.messages;
    final thinking = widget.controller.isThinking;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: messages.length + (thinking ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index >= messages.length) return const _ThinkingBubble();
              return MessageBubble(message: messages[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _hintFor(widget.controller.state!.stage),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  style: IconButton.styleFrom(
                    backgroundColor: NexusColors.violet,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _hintFor(Stage stage) => switch (stage) {
        Stage.nouveauNe => 'Parle-lui, même à vide…',
        Stage.nourrisson => 'Dis-lui un mot…',
        Stage.petitParleur => 'Apprends-lui une phrase…',
        _ => 'Écris-lui quelque chose…',
      };
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: NexusColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 34,
          height: 12,
          child: _Dots(),
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(3, (int index) {
            final phase = (_controller.value + index * 0.22) % 1;
            final opacity = 0.25 + 0.75 * (1 - (phase * 2 - 1).abs());
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NexusColors.muted.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
