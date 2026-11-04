import 'package:flutter/material.dart';

import '../config.dart';
import '../controller/nexus_controller.dart';
import '../data/update_service.dart';
import '../theme.dart';

/// La mise à jour, faite depuis Nexus : vérification, téléchargement contrôlé
/// et installation, sans passer par un navigateur.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final UpdateCheck? check = controller.lastUpdateCheck;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: controller.updateAvailable
              ? NexusColors.mint.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Mise à jour',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NexusColors.text,
                  ),
                ),
              ),
              Text(
                'v${AppConfig.version}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: NexusColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._content(check),
        ],
      ),
    );
  }

  List<Widget> _content(UpdateCheck? check) {
    if (controller.isCheckingUpdate) {
      return const <Widget>[
        _Status(
          icon: Icons.hourglass_top_rounded,
          color: NexusColors.muted,
          text: 'Je regarde si une nouvelle version existe…',
        ),
      ];
    }

    if (controller.downloadingUpdate) {
      final int percent =
          (controller.updateProgress * 100).clamp(0, 100).round();
      return <Widget>[
        Text(
          'Téléchargement de la version ${check?.manifest?.version ?? ''} : '
          '$percent %',
          style: const TextStyle(color: NexusColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: controller.updateProgress <= 0
                ? null
                : controller.updateProgress,
            minHeight: 8,
            backgroundColor: NexusColors.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(NexusColors.mint),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "L'APK est vérifié par son empreinte avant d'être proposé à Android.",
          style: TextStyle(
            color: NexusColors.muted,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ];
    }

    if (controller.updateReadyToInstall) {
      return <Widget>[
        _Status(
          icon: controller.installAllowed
              ? Icons.download_done_rounded
              : Icons.lock_outline_rounded,
          color: NexusColors.mint,
          text: controller.installAllowed
              ? 'Mise à jour téléchargée et vérifiée. Android va demander '
                  'confirmation.'
              : 'Android demande ton autorisation pour installer une '
                  'application depuis Nexus.',
        ),
        const SizedBox(height: 12),
        if (controller.installAllowed)
          _MainButton(
            label: 'Installer la mise à jour',
            icon: Icons.system_update_alt_rounded,
            onPressed: controller.installPendingUpdate,
          )
        else
          _MainButton(
            label: "Autoriser l'installation",
            icon: Icons.settings_applications_rounded,
            onPressed: controller.grantInstallPermission,
          ),
        if (controller.updateError != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            controller.updateError!,
            style: const TextStyle(
              color: NexusColors.rose,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          "Si Android répond « paquet en conflit », c'est qu'une version plus "
          'ancienne est encore là avec une autre signature : désinstalle-la '
          'une seule fois, puis réinstalle. Les suivantes passent sans rien '
          'perdre.',
          style: TextStyle(
            color: NexusColors.muted,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ];
    }

    if (check == null) {
      return <Widget>[
        const Text(
          "Nexus vérifie son manifeste signé et peut s'installer elle-même la "
          'nouvelle version : le téléchargement et la vérification se font ici.',
          style: TextStyle(
            color: NexusColors.muted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        _MainButton(
          label: 'Vérifier les mises à jour',
          icon: Icons.refresh_rounded,
          onPressed: controller.checkForUpdates,
        ),
      ];
    }

    switch (check.status) {
      case UpdateStatus.locked:
        return <Widget>[
          const _Status(
            icon: Icons.lock_outline_rounded,
            color: NexusColors.muted,
            text: "Cette version n'a pas été signée : les mises à jour "
                'automatiques sont désactivées.',
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: 'Ouvrir la page des versions',
            onPressed: controller.openReleases,
          ),
        ];

      case UpdateStatus.upToDate:
        return <Widget>[
          _Status(
            icon: Icons.verified_rounded,
            color: NexusColors.mint,
            text: 'Tu es à jour (v${AppConfig.version}).',
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: 'Revérifier',
            onPressed: controller.checkForUpdates,
          ),
        ];

      case UpdateStatus.available:
        final manifest = check.manifest!;
        return <Widget>[
          _Status(
            icon: Icons.new_releases_rounded,
            color: NexusColors.mint,
            text: 'La version ${manifest.version} est disponible '
                '(tu as la ${AppConfig.version}).',
          ),
          if (manifest.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              manifest.notes.trim(),
              style: const TextStyle(
                color: NexusColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _MainButton(
            label: 'Mettre à jour maintenant',
            icon: Icons.system_update_alt_rounded,
            onPressed: controller.downloadAndInstallUpdate,
          ),
          if (controller.updateError != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              controller.updateError!,
              style: const TextStyle(
                color: NexusColors.rose,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _SecondaryButton(
            label: 'Ouvrir la page de téléchargement',
            onPressed: () => controller.openUpdate(),
          ),
        ];

      case UpdateStatus.invalid:
        return <Widget>[
          const _Status(
            icon: Icons.gpp_bad_rounded,
            color: NexusColors.rose,
            text: 'Manifeste non signé ou altéré : mise à jour refusée.',
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: 'Ouvrir la page des versions',
            onPressed: controller.openReleases,
          ),
        ];

      case UpdateStatus.failed:
        return <Widget>[
          _Status(
            icon: Icons.cloud_off_rounded,
            color: NexusColors.muted,
            text: 'Vérification impossible : ${check.message}'.trim(),
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: 'Réessayer',
            onPressed: controller.checkForUpdates,
          ),
        ];
    }
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
