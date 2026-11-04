import 'package:flutter/material.dart';

import '../controller/nexus_controller.dart';
import '../data/brain_catalogue.dart';
import '../data/llm_service.dart';
import '../theme.dart';

/// Bandeau discret affiché au-dessus de la conversation tant qu'aucun cerveau
/// n'est chargé.
class BrainBanner extends StatelessWidget {
  const BrainBanner({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.brainReady) return const SizedBox.shrink();

    final status = controller.brainStatus;
    final percent = controller.brainProgress;
    final busy = controller.brainBusy;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusColors.violet.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            busy ? Icons.downloading_rounded : Icons.psychology_outlined,
            size: 18,
            color: NexusColors.violet,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _label(status, percent, controller),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: NexusColors.muted,
                    height: 1.35,
                  ),
                ),
                if (busy) ...<Widget>[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent == null ? null : percent / 100,
                      minHeight: 5,
                      backgroundColor: NexusColors.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        NexusColors.violet,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!busy &&
              (status == BrainStatus.absent || status == BrainStatus.failed))
            TextButton(
              onPressed: () => controller.useBrain(controller.activeBrain),
              child:
                  Text(status == BrainStatus.failed ? 'Réessayer' : 'Installer'),
            ),
        ],
      ),
    );
  }

  static String _label(
    BrainStatus status,
    double? percent,
    NexusController controller,
  ) {
    final brain = controller.activeBrain;
    switch (status) {
      case BrainStatus.checking:
        return 'Je regarde quels cerveaux sont déjà là…';
      case BrainStatus.absent:
        return "Aucun cerveau installé : je babille pour le moment. Choisis-en "
            'un dans l\'onglet Cerveau, une seule fois.';
      case BrainStatus.downloading:
        return percent == null
            ? 'Téléchargement de ${brain.label}…'
            : 'Téléchargement de ${brain.label} : ${percent.round()} %';
      case BrainStatus.loading:
        return 'Je charge ${brain.label} en mémoire…';
      case BrainStatus.ready:
        return 'Cerveau actif : ${brain.label}.';
      case BrainStatus.failed:
        return '${brain.label} n\'a pas pu être chargé.';
    }
  }
}

/// Les cerveaux disponibles : tous locaux, un seul allumé à la fois.
class BrainCard extends StatelessWidget {
  const BrainCard({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PanelTitle('Ses cerveaux'),
          const SizedBox(height: 10),
          const Text(
            'Plusieurs réseaux de neurones, tous exécutés sur ton téléphone '
            'par llama.cpp. Un seul est allumé à la fois, et aucun n\'a besoin '
            'd\'Internet pour te répondre.',
            style: TextStyle(
              color: NexusColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          for (final BrainVariant brain in controller.brains) ...<Widget>[
            _BrainRow(controller: controller, brain: brain),
            const SizedBox(height: 10),
          ],
          const Text(
            'Changer de cerveau ne coûte rien une fois téléchargé : le fichier '
            'reste sur le téléphone et se rallume instantanément.',
            style: TextStyle(color: NexusColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _BrainRow extends StatelessWidget {
  const _BrainRow({required this.controller, required this.brain});

  final NexusController controller;
  final BrainVariant brain;

  @override
  Widget build(BuildContext context) {
    final bool active = controller.activeBrain.id == brain.id &&
        controller.brainStatus == BrainStatus.ready;
    final bool installed = controller.isBrainInstalled(brain);
    final bool busy =
        controller.brainBusy && controller.activeBrain.id == brain.id;
    final bool locked = controller.brainBusy && !busy;
    final double? percent = controller.brainProgress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexusColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? NexusColors.mint.withValues(alpha: 0.55)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  brain.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NexusColors.text,
                  ),
                ),
              ),
              if (active)
                const _Chip(
                  text: 'Allumé',
                  color: NexusColors.mint,
                  icon: Icons.bolt_rounded,
                )
              else if (installed)
                const _Chip(
                  text: 'Installé',
                  color: NexusColors.muted,
                  icon: Icons.check_circle_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            brain.tagline,
            style: const TextStyle(
              color: NexusColors.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brain.sizeLabel,
            style: const TextStyle(color: NexusColors.muted, fontSize: 11.5),
          ),
          if (busy) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent == null ? null : percent / 100,
                minHeight: 7,
                backgroundColor: NexusColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  NexusColors.violet,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.brainStatus == BrainStatus.downloading
                  ? 'Téléchargement : '
                      '${percent == null ? '…' : '${percent.round()} %'}'
                  : 'Chargement des poids en mémoire…',
              style: const TextStyle(color: NexusColors.muted, fontSize: 11.5),
            ),
          ],
          if (!active) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: installed
                  ? OutlinedButton.icon(
                      onPressed:
                          locked ? null : () => controller.useBrain(brain),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Allumer ce cerveau'),
                    )
                  : FilledButton.icon(
                      onPressed:
                          locked ? null : () => controller.useBrain(brain),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text('Télécharger (${brain.sizeLabel})'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11.5)),
      ],
    );
  }
}

/// Les règles de personnalité : c'est ici que tu la diriges.
class PersonaCard extends StatelessWidget {
  const PersonaCard({super.key, required this.controller});

  final NexusController controller;

  static const String _example =
      'Tu t\'appelles Nexus. Tu me parles comme une amie proche, sans '
      'flatterie. Tu es directe, un peu moqueuse, et tu n\'inventes jamais '
      'un souvenir. Tu ne me fais pas de morale.';

  @override
  Widget build(BuildContext context) {
    final persona = controller.persona.trim();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PanelTitle('Ses règles (écrites par toi)'),
          const SizedBox(height: 12),
          Text(
            persona.isEmpty
                ? 'Aucune règle pour l\'instant : elle est libre. Elle dit ce '
                    'qu\'elle pense, sans morale ni pruderie, et elle te répond '
                    'toujours franchement. Écris ici qui elle est et comment '
                    'elle te parle.'
                : persona,
            style: TextStyle(
              color: persona.isEmpty ? NexusColors.muted : NexusColors.text,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(
                persona.isEmpty ? 'Écrire ses règles' : 'Modifier ses règles',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ces règles sont envoyées au modèle à chaque message : elles le '
            'dirigent immédiatement.',
            style: TextStyle(color: NexusColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final TextEditingController field =
        TextEditingController(text: controller.persona);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: NexusColors.surfaceHigh,
        title: const Text('Qui est Nexus ?'),
        content: TextField(
          controller: field,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: _example,
            hintMaxLines: 6,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(field.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    field.dispose();
    if (result != null) {
      await controller.setPersona(result);
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: NexusColors.text,
      ),
    );
  }
}
