import 'package:flutter/material.dart';

import 'controller/nexus_controller.dart';
import 'data/nexus_store.dart';
import 'data/tts_service.dart';
import 'data/update_service.dart';
import 'theme.dart';
import 'ui/birth_screen.dart';
import 'ui/nexus_screen.dart';
import 'ui/widgets/nexus_orb.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NexusApp(store: NexusStore()));
}

class NexusApp extends StatefulWidget {
  const NexusApp({super.key, required this.store});

  final NexusStore store;

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> {
  late final NexusController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NexusController(
      widget.store,
      tts: TtsService(),
      updates: UpdateService(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: buildNexusTheme(),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          if (_controller.isLoading) {
            return const Scaffold(
              body: Center(child: NexusOrb(size: 110)),
            );
          }
          if (!_controller.hasNexus) {
            return BirthScreen(controller: _controller);
          }
          return NexusScreen(controller: _controller);
        },
      ),
    );
  }
}
