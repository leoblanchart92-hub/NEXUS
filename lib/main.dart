import 'package:flutter/material.dart';

import 'theme.dart';
import 'ui/ai_home_view.dart';

void main() => runApp(const NexusApp());

/// Nexus : télécharger des IA, les allumer, les éteindre.
class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: buildNexusTheme(),
      home: const AiHomeView(),
    );
  }
}
