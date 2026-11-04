import 'package:flutter/material.dart';
import 'package:nexus_core/nexus_core.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';

/// L'onglet « Grandir » : tout ce que Nexus est devenu.
class GrowthView extends StatelessWidget {
  const GrowthView({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final next = state.stage.nextStage;
    final words = state.lexicon.topWords;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    state.stage.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          state.stage.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${state.ageInDays} jour${state.ageInDays > 1 ? 's' : ''} de vie',
                          style: const TextStyle(
                            color: NexusColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${state.xp} xp',
                    style: const TextStyle(
                      color: NexusColors.mint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                state.stage.description,
                style: const TextStyle(color: NexusColors.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.stageProgress,
                  minHeight: 8,
                  backgroundColor: NexusColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    NexusColors.violet,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                next == null
                    ? 'Il a atteint son dernier stade. Il continue d\'apprendre.'
                    : 'Prochain stade : ${next.label} dans ${state.xpToNextStage} xp',
                style: const TextStyle(color: NexusColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _CardTitle('Ses besoins'),
              const SizedBox(height: 12),
              _NeedBar(
                label: 'Énergie',
                value: state.needs.energy,
                color: NexusColors.amber,
              ),
              _NeedBar(
                label: 'Présence',
                value: state.needs.attention,
                color: NexusColors.rose,
              ),
              _NeedBar(
                label: 'Curiosité',
                value: state.needs.curiosity,
                color: NexusColors.mint,
              ),
              const SizedBox(height: 4),
              Text(
                'Humeur : ${state.needs.mood}',
                style: const TextStyle(color: NexusColors.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _CardTitle('Son cerveau'),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  _Stat(
                    value: '${state.lexicon.size}',
                    label: 'mots',
                  ),
                  _Stat(
                    value: '${state.exchanges}',
                    label: 'échanges',
                  ),
                  _Stat(
                    value: '${state.memory.episodes.length}',
                    label: 'souvenirs',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (words.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _CardTitle('Ses mots'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final word in words.take(40))
                      Chip(
                        label: Text(
                          word,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        backgroundColor: NexusColors.surfaceHigh,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (state.memory.episodes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _CardTitle('Ses souvenirs'),
                const SizedBox(height: 8),
                for (final episode in state.memory.episodes.reversed.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: NexusColors.violet,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            episode.text,
                            style: const TextStyle(
                              color: NexusColors.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        TextButton.icon(
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.restart_alt, color: NexusColors.rose),
          label: const Text(
            'Le faire renaître de zéro',
            style: TextStyle(color: NexusColors.rose),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: NexusColors.surfaceHigh,
        title: const Text('Le faire renaître ?'),
        content: const Text(
          'Tout son vocabulaire et tous ses souvenirs seront effacés. '
          'Nexus redeviendra un nouveau-né.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer', style: TextStyle(color: NexusColors.rose)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.reset();
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: NexusColors.muted,
      ),
    );
  }
}

class _NeedBar extends StatelessWidget {
  const _NeedBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: NexusColors.muted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: NexusColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: NexusColors.muted),
          ),
        ],
      ),
    );
  }
}
