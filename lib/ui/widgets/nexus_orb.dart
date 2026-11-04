import 'package:flutter/material.dart';

import '../../theme.dart';

/// La boule de conscience de Nexus : elle respire, toujours.
class NexusOrb extends StatefulWidget {
  const NexusOrb({
    super.key,
    this.size = 96,
    this.color = NexusColors.violet,
    this.pulse = true,
  });

  final double size;
  final Color color;
  final bool pulse;

  @override
  State<NexusOrb> createState() => _NexusOrbState();
}

class _NexusOrbState extends State<NexusOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = widget.pulse ? _controller.value : 0.35;
        return Transform.scale(
          scale: 1 + 0.07 * t,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Colors.white,
                  widget.color.withValues(alpha: 0.9),
                  widget.color.withValues(alpha: 0.2),
                ],
                stops: const <double>[0, 0.4, 1],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3 + 0.35 * t),
                  blurRadius: 24 + 26 * t,
                  spreadRadius: 2 + 5 * t,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
