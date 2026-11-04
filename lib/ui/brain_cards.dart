import 'package:flutter/material.dart';

import '../config.dart';
import '../controller/nexus_controller.dart';
import '../data/llm_service.dart';
import '../theme.dart';

/// Bandeau discret affiché au-dessus de la conversation tant que le cerveau
/// neuronal n'est pas chargé.
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
                  _label(status, percent),
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
              (status == BrainStatus.absent ||
                  status == BrainStatus.failed))
            TextButton(
              onPressed: controller.downloadBrain,
              child:
                  Text(status == BrainStatus.failed ? 'Réessayer' : 'Installer'),
            ),
        ],
      ),
    );
  }

  static String _label(BrainStatus status, double? percent) {
    switch (status) {
      case BrainStatus.checking:
        return 'Je regarde si mon cerveau est déjà là…';
      case BrainStatus.absent:
        return "Mon cerveau neuronal n'est pas encore installé : je babille "
            'pour le moment. 1,03 Go, une seule fois.';
      case BrainStatus.downloading:
        return percent == null
            ? 'Téléchargement de mon cerveau…'
            : 'Téléchargement de mon cerveau : ${percent.round()} %';
      case BrainStatus.loading:
        return 'Je charge mon cerveau en mémoire…';
      case BrainStatus.ready:
        return 'Cerveau neuronal actif.';
      case BrainStatus.failed:
        return 'Mon cerveau n\'a pas pu être chargé.';
    }
  }
}

/// La carte du cerveau : installation, état, et ce qu'elle implique.
class BrainCard extends StatelessWidget {
  const BrainCard({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.brainStatus;
    final percent = controller.brainProgress;
    final busy = controller.brainBusy;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _PanelTitle('Son vrai cerveau'),
          const SizedBox(height: 12),
          const Text(
            'Un réseau de neurones de 1,7 milliard de paramètres (Qwen3-1.7B) '
            'tourne directement sur ton téléphone. Aucune requête ne part sur '
            'Internet : tout le calcul se fait ici.',
            style: TextStyle(
              color: NexusColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (status == BrainStatus.ready)
            const Row(
              children: <Widget>[
                Icon(Icons.check_circle, size: 16, color: NexusColors.mint),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cerveau chargé et actif, hors ligne.',
                    style: TextStyle(color: NexusColors.mint, fontSize: 13),
                  ),
                ),
              ],
            )
          else if (busy) ...<Widget>[
            Text(
              status == BrainStatus.downloading
                  ? 'Téléchargement : '
                      '${percent == null ? '…' : '${percent.round()} %'}  '
                      '(${(AppConfig.brainBytes / 1073741824).toStringAsFixed(2)} Go)'
                  : 'Chargement des poids en mémoire…',
              style: const TextStyle(color: NexusColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent == null ? null : percent / 100,
                minHeight: 8,
                backgroundColor: NexusColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  NexusColors.violet,
                ),
              ),
            ),
          ] else ...<Widget>[
            if (status == BrainStatus.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  controller.brainError ?? 'Échec du chargement.',
                  style: const TextStyle(
                    color: NexusColors.rose,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.downloadBrain,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  status == BrainStatus.failed
                      ? 'Réessayer'
                      : 'Télécharger son cerveau (1,03 Go)',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'À faire une seule fois, en Wi-Fi. Ensuite, elle fonctionne sans '
              'aucune connexion.',
              style: TextStyle(color: NexusColors.muted, fontSize: 11.5),
            ),
          ],
        ],
      ),
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
                ? 'Aucune règle pour l\'instant : elle se comporte comme une '
                    'IA curieuse et honnête. Écris ici qui elle est, comment '
                    'elle te parle, ce qu\'elle n\'a pas le droit de faire.'
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
