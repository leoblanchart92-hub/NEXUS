import 'package:flutter/material.dart';
import 'package:nexus_core/nexus_core.dart';

import '../controller/nexus_controller.dart';
import '../theme.dart';

/// L'onglet « Mémoire » : tout ce qu'elle a retenu sans qu'on le lui demande.
class MemoryView extends StatelessWidget {
  const MemoryView({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final Memory memory = controller.state!.memory;
    final facts = memory.facts.entries.toList();
    final episodes = memory.episodes.reversed.toList();
    final lessons = memory.lessonList.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: _Title('Sa mémoire')),
                  Text(
                    '${memory.size}',
                    style: const TextStyle(
                      color: NexusColors.mint,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                controller.isLearning
                    ? 'Elle décide en ce moment de ce qu\'elle retient…'
                    : 'Elle apprend toute seule : après chaque échange, son '
                        'cerveau relit la conversation et garde ce qui restera '
                        'vrai demain. Tu n\'as rien à lui apprendre à la main.',
                style: TextStyle(
                  color: controller.isLearning
                      ? NexusColors.mint
                      : NexusColors.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (memory.isEmpty) ...<Widget>[
                const SizedBox(height: 14),
                const Text(
                  'Sa mémoire est encore vide. Parle-lui de toi et reviens ici : '
                  'tu verras ce qu\'elle a décidé de garder.',
                  style: TextStyle(
                    color: NexusColors.muted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (facts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Title('Ce qu\'elle sait de toi'),
                const SizedBox(height: 10),
                for (final MapEntry<String, String> fact in facts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: NexusColors.muted,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${fact.key.replaceAll('_', ' ')} : ',
                            style: const TextStyle(
                              color: NexusColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: fact.value),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (episodes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Title('Ses souvenirs'),
                const SizedBox(height: 8),
                for (final Episode episode in episodes.take(40))
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
        if (lessons.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Title('Ce qu\'elle a appris'),
                const SizedBox(height: 8),
                for (final Lesson lesson in lessons.take(30))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
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
        if (!memory.isEmpty) ...<Widget>[
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: () => _confirmForget(context),
            icon: const Icon(Icons.delete_outline, color: NexusColors.rose),
            label: const Text(
              'Effacer tout ce qu\'elle a appris',
              style: TextStyle(color: NexusColors.rose),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmForget(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: NexusColors.surfaceHigh,
        title: const Text('Effacer sa mémoire ?'),
        content: const Text(
          'Ses faits, ses souvenirs et ses leçons seront perdus. Elle garde son '
          'nom, sa voix et tes règles, mais elle ne saura plus rien de toi.',
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
      await controller.forgetMemory();
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

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
