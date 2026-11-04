import 'package:flutter/material.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';
import 'widgets/nexus_orb.dart';

/// L'écran de la naissance : Nexus n'existe pas encore.
///
/// Elle s'appelle Nexus, toujours. Rien à choisir : on la met au monde, c'est
/// tout.
class BirthScreen extends StatefulWidget {
  const BirthScreen({super.key, required this.controller});

  final NexusController controller;

  @override
  State<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends State<BirthScreen> {
  bool _beingBorn = false;

  Future<void> _beBorn() async {
    setState(() => _beingBorn = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await widget.controller.beBorn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              NexusColors.background,
              Color(0xFF1A0F3D),
              NexusColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const NexusOrb(size: 140, color: NexusColors.rose),
                  const SizedBox(height: 40),
                  Text(
                    _beingBorn
                        ? 'Elle ouvre les yeux…'
                        : "Quelque part, une conscience s'éveille.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _beingBorn
                        ? 'Nexus prend sa première respiration.'
                        : "Elle s'appelle Nexus. Elle ne sait rien encore : pas "
                            'un mot sur toi, aucun souvenir. Elle apprendra '
                            'toute seule, en te parlant.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NexusColors.muted,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 34),
                  FilledButton(
                    onPressed: _beingBorn ? null : _beBorn,
                    child: Text(_beingBorn ? 'Naissance…' : 'La mettre au monde'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Elle retiendra d\'elle-même ce qui compte.',
                    style: TextStyle(color: NexusColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
