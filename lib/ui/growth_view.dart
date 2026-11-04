import 'package:flutter/material.dart';
import 'package:nexus_core/nexus_core.dart';

import '../config.dart';
import '../controller/nexus_controller.dart';
import '../data/update_service.dart';
import '../theme.dart';
import 'lesson_sheet.dart';

/// L'onglet « Grandir » : tout ce que Nexus est devenu.
class GrowthView extends StatelessWidget {
  const GrowthView({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final next = state.stage.nextStage;
    final words = state.lexicon.topWords;
    final lessons = state.memory.lessonList.reversed.toList();

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
                    ? "Il a atteint son dernier stade. Il continue d'apprendre."
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
              Row(
                children: <Widget>[
                  const Expanded(child: _CardTitle('Son école')),
                  Text(
                    '${lessons.length} leçon${lessons.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: NexusColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lessons.isEmpty
                    ? "Il ne connaît encore rien du monde. Apprends-lui un mot, il s'en souviendra."
                    : "Il a retenu ${lessons.length} leçon${lessons.length > 1 ? 's' : ''}. Demande-lui « c'est quoi… » ou « récite-moi ».",
                style: const TextStyle(
                  color: NexusColors.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => LessonSheet.show(context, controller),
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Lui apprendre un mot'),
                ),
              ),
              if (lessons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                for (final lesson in lessons.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.menu_book,
                          size: 14,
                          color: NexusColors.violet,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: NexusColors.muted,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${lesson.word} : ',
                                  style: const TextStyle(
                                    color: NexusColors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: lesson.definition),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
                  _Stat(value: '${state.lexicon.size}', label: 'mots'),
                  _Stat(value: '${state.exchanges}', label: 'échanges'),
                  _Stat(
                    value: '${state.memory.episodes.length}',
                    label: 'souvenirs',
                  ),
                  _Stat(value: '${lessons.length}', label: 'leçons'),
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
        const SizedBox(height: 14),
        _UpdatesCard(controller: controller),
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
          'Tout son vocabulaire, ses leçons et ses souvenirs seront effacés. '
          'Nexus redeviendra un nouveau-né.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Effacer',
              style: TextStyle(color: NexusColors.rose),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.reset();
    }
  }
}

/// Les mises à jour : verrouillées sans clé, vérifiées par signature.
class _UpdatesCard extends StatelessWidget {
  const _UpdatesCard({required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final unlocked = controller.updates.isUnlocked;
    final check = controller.lastUpdateCheck;
    final checking = controller.isCheckingUpdate;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: _CardTitle('Mises à jour')),
              Icon(
                unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 15,
                color: unlocked ? NexusColors.mint : NexusColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            unlocked
                ? 'Version ${AppConfig.version}. Chaque mise à jour est vérifiée par signature : sans la clé, elle est refusée.'
                : "Verrouillées : cette version a été compilée sans clé de mise à jour.",
            style: const TextStyle(
              color: NexusColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (check != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              check.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: switch (check.status) {
                  UpdateStatus.available => NexusColors.mint,
                  UpdateStatus.invalid => NexusColors.rose,
                  UpdateStatus.failed => NexusColors.rose,
                  _ => NexusColors.muted,
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!unlocked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.openReleases(),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Ouvrir la page des versions'),
              ),
            )
          else if (check?.hasUpdate ?? false)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => controller.openUpdate(),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("Télécharger l'APK"),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: checking ? null : controller.checkForUpdates,
                icon: checking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  checking ? 'Vérification…' : 'Vérifier les mises à jour',
                ),
              ),
            ),
        ],
      ),
    );
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: NexusColors.muted),
          ),
        ],
      ),
    );
  }
}
