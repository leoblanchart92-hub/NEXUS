import 'package:flutter/material.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';
import 'brain_view.dart';
import 'chat_view.dart';
import 'memory_view.dart';
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
                    MemoryView(controller: widget.controller),
                    BrainView(controller: widget.controller),
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
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Parler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Mémoire',
          ),
          NavigationDestination(
            // Une pastille quand une nouvelle version attend d'être installée.
            icon: Badge(
              isLabelVisible: widget.controller.updateAvailable,
              backgroundColor: NexusColors.mint,
              child: const Icon(Icons.psychology_outlined),
            ),
            selectedIcon: const Icon(Icons.psychology),
            label: 'Cerveau',
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
    final count = state.memory.size;

    final String subtitle;
    if (controller.isLearning) {
      subtitle = 'Elle retient ce que tu viens de dire…';
    } else if (controller.brainBusy) {
      subtitle = 'Son cerveau se prépare…';
    } else if (!controller.brainReady) {
      subtitle = 'Cerveau non installé';
    } else if (count == 0) {
      subtitle = 'Sa mémoire est vide';
    } else {
      subtitle = '$count choses retenues';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
      child: Row(
        children: <Widget>[
          NexusOrb(
            size: 52,
            color: controller.brainReady
                ? NexusColors.violet
                : NexusColors.rose,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  state.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: controller.brainReady
                        ? NexusColors.muted
                        : NexusColors.rose,
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
