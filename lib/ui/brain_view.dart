import 'package:flutter/material.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';
import 'brain_cards.dart';
import 'update_card.dart';

/// L'onglet « Cerveau » : installer le modèle neuronal et écrire ses règles.
class BrainView extends StatelessWidget {
  const BrainView({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        UpdateCard(controller: controller),
        const SizedBox(height: 14),
        BrainCard(controller: controller),
        const SizedBox(height: 14),
        PersonaCard(controller: controller),
        const SizedBox(height: 14),
        const _PrivacyCard(),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Ce qui reste chez toi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: NexusColors.muted,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Le modèle est téléchargé une seule fois, puis exécuté sur le '
            'téléphone. Ni tes messages, ni sa mémoire, ni ses réponses ne '
            'partent sur un serveur. Seul le téléchargement initial du cerveau '
            'utilise Internet.',
            style: TextStyle(
              color: NexusColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
