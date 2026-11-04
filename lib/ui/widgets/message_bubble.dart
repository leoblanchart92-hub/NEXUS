import 'package:flutter/material.dart';

import '../../controller/nexus_controller.dart';
import '../../theme.dart';

/// Une bulle de conversation.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: NexusColors.mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NexusColors.mint.withValues(alpha: 0.4)),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NexusColors.mint,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final fromNexus = message.fromNexus;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: fromNexus ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: fromNexus ? NexusColors.surfaceHigh : NexusColors.violet,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(fromNexus ? 4 : 20),
            bottomRight: Radius.circular(fromNexus ? 20 : 4),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: fromNexus ? NexusColors.text : Colors.white,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
