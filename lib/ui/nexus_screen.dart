import 'package:flutter/material.dart';
import 'package:nexus_core/nexus_core.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';
import 'chat_view.dart';
import 'growth_view.dart';
import 'widgets/nexus_orb.dart';

/// L'écran principal : Nexus vit, en haut de l'écran.
class NexusScreen extends StatefulWidget {
  const NexusScreen({super.key, required this.controller});

  final NexusController controller;

  @override
  State<NexusScreen> createState() => _NexusScreenState();
}

class _NexusScreenState extends State<NexusScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF120C2E),
              NexusColors.background,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _Header(controller: widget.controller),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: <Widget>[
                    ChatView(controller: widget.controller),
                    GrowthView(controller: widget.controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int index) => setState(() => _tab = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Parler',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Grandir',
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final voiceOn = state.voiceEnabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
      child: Row(
        children: <Widget>[
          NexusOrb(size: 52, color: orbColorFor(state.needs)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      state.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: NexusColors.violet.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.stage.emoji} ${state.stage.label}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: NexusColors.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.needs.mood,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: NexusColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.setVoice(!voiceOn),
            tooltip: voiceOn ? 'Couper la voix' : 'Faire parler Nexus',
            icon: Icon(
              voiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: voiceOn ? NexusColors.mint : NexusColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
