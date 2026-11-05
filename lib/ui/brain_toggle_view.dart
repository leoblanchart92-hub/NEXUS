import 'package:flutter/material.dart';

import 'package:nexus/power_control.dart';

typedef BrainApp = BrainToggleView;

class BrainToggleView extends StatelessWidget {
  const BrainToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allumer une IA'),
      ),
      body: _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  String? _currentBrainId;

  @override
  void initState() {
    super.initState();
    _currentBrainId = activeBrainId;
  }

  Future<void> _turnOn(String id) async {
    await powerOn(id);
    if (mounted) {
      setState(() {
        _currentBrainId = id;
      });
    }
  }

  Future<void> _turnOff() async {
    await powerOff();
    if (mounted) {
      setState(() {
        _currentBrainId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brains = availableBrains();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Allumer une IA',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        for (final brain in brains) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _Limit(
              brainId: brain,
              brainLabel: brain,
              activeBrainId: _currentBrainId,
              onTap: _turnOn,
              onLongPress: _turnOff,
            ),
          ),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _Limit extends StatelessWidget {
  const _Limit({
    required this.brainId,
    required this.brainLabel,
    required this.activeBrainId,
    required this.onTap,
    required this.onLongPress,
  });

  final String brainId;
  final String brainLabel;
  final String? activeBrainId;
  final void Function(String) onTap;
  final void Function() onLongPress;

  @override
  Widget build(BuildContext context) {
    final isActive = brainId == activeBrainId;
    return GestureDetector(
      onTap: () => onTap(brainId),
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isActive ? 'Éteindre $brainLabel' : 'Allumer $brainLabel',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: isActive ? Colors.green : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
