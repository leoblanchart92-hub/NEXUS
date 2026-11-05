import 'dart:async';

import 'package:flutter/material.dart';

import '../ai_catalogue.dart';
import '../local_ai_service.dart';
import '../theme.dart';

/// L'écran principal : la liste des IA, à télécharger d'abord, puis à allumer
/// et éteindre.
class AiHomeView extends StatefulWidget {
  const AiHomeView({super.key});

  @override
  State<AiHomeView> createState() => _AiHomeViewState();
}

class _AiHomeViewState extends State<AiHomeView> {
  final LocalAiService _service = LocalAiService();

  @override
  void initState() {
    super.initState();
    unawaited(_service.start());
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _service,
          builder: (BuildContext context, Widget? child) {
            final String? activeId = _service.activeId;
            final LocalAi? running = activeId == null ? null : aiById(activeId);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              children: <Widget>[
                _Header(
                  running: running,
                  onPowerOffAll:
                      _service.busy ? null : () => _service.powerOffAll(),
                ),
                const SizedBox(height: 22),
                for (final LocalAi ai in aiCatalogue) ...<Widget>[
                  _AiCard(
                    ai: ai,
                    state: _service.stateOf(ai),
                    service: _service,
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 10),
                Text(
                  'Une seule IA tourne à la fois : deux modèles ensemble ne '
                  'tiennent pas dans la mémoire vive du téléphone. Éteinte, une '
                  'IA ne consomme rien — son fichier reste là, prêt à rallumer.',
                  style: const TextStyle(
                    color: NexusColors.muted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.running, required this.onPowerOffAll});

  final LocalAi? running;
  final VoidCallback? onPowerOffAll;

  @override
  Widget build(BuildContext context) {
    final LocalAi? live = running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Nexus',
          style: TextStyle(
            color: NexusColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tes IA vivent ici, sur ton téléphone. Télécharge-les une fois, '
          'puis allume celle que tu veux.',
          style: TextStyle(
            color: NexusColors.muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: NexusColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusColors.surfaceHigh),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: live == null ? NexusColors.muted : NexusColors.mint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  live == null
                      ? 'Aucune IA allumée'
                      : '${live.label} tourne en mémoire',
                  style: TextStyle(
                    color: live == null ? NexusColors.muted : NexusColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (live != null)
                TextButton(
                  onPressed: onPowerOffAll,
                  style: TextButton.styleFrom(
                    foregroundColor: NexusColors.rose,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Tout éteindre'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.ai, required this.state, required this.service});

  final LocalAi ai;
  final AiState state;
  final LocalAiService service;

  bool get _isRunning => state.phase == AiPhase.running;
  bool get _isReady => state.phase == AiPhase.ready;
  bool get _isAbsent => state.phase == AiPhase.absent;
  bool get _isDownloading => state.phase == AiPhase.downloading;
  bool get _isLoading => state.phase == AiPhase.loading;
  bool get _isChecking => state.phase == AiPhase.checking;
  bool get _isFailed => state.phase == AiPhase.failed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !service.busy;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRunning
              ? NexusColors.mint.withValues(alpha: 0.65)
              : NexusColors.surfaceHigh,
          width: _isRunning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ai.label,
                      style: const TextStyle(
                        color: NexusColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ai.tagline,
                      style: const TextStyle(
                        color: NexusColors.muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Badge(phase: state.phase),
            ],
          ),
          const SizedBox(height: 16),
          _action(context, enabled),
          if (_isDownloading) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (state.progress ?? 0) / 100,
                minHeight: 6,
                backgroundColor: NexusColors.surfaceHigh,
                color: NexusColors.violet,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressLabel(),
              style: const TextStyle(
                color: NexusColors.muted,
                fontSize: 12,
              ),
            ),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: const TextStyle(
                color: NexusColors.rose,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _progressLabel() {
    final double percent = state.progress ?? 0;
    final int done = (ai.bytes * percent / 100).round();
    return '${percent.round()} % · ${formatBytes(done)} sur ${ai.sizeLabel}';
  }

  Widget _action(BuildContext context, bool enabled) {
    if (_isAbsent) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled ? () => service.download(ai) : null,
          icon: const Icon(Icons.download_rounded, size: 20),
          label: Text('Télécharger · ${ai.sizeLabel}'),
        ),
      );
    }

    if (_isDownloading) {
      return const Text(
        'Téléchargement en cours…',
        style: TextStyle(
          color: NexusColors.text,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (_isLoading) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: NexusColors.violet,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Chargement des poids de ${ai.label}…',
            style: const TextStyle(color: NexusColors.text, fontSize: 13.5),
          ),
        ],
      );
    }

    if (_isChecking) {
      return const Text(
        'Vérification du téléphone…',
        style: TextStyle(color: NexusColors.muted, fontSize: 13.5),
      );
    }

    if (_isFailed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: enabled ? () => service.download(ai) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: NexusColors.text,
            side: const BorderSide(color: NexusColors.surfaceHigh),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Réessayer'),
        ),
      );
    }

    // Présente sur le téléphone : on l'allume, ou on l'éteint.
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled
                ? () =>
                    _isRunning ? service.powerOff(ai) : service.powerOn(ai)
                : null,
            style: _isRunning
                ? FilledButton.styleFrom(
                    backgroundColor: NexusColors.mint,
                    foregroundColor: NexusColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  )
                : FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
            icon: Icon(
              _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 20,
            ),
            label: Text(_isRunning ? 'Éteindre' : 'Allumer'),
          ),
        ),
        if (_isReady) ...<Widget>[
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? () => _confirmRemove(context) : null,
            tooltip: 'Supprimer du téléphone',
            icon: const Icon(Icons.delete_outline_rounded),
            color: NexusColors.muted,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: NexusColors.surfaceHigh,
        title: Text('Supprimer ${ai.label} ?'),
        content: Text(
          'Le fichier (${ai.sizeLabel}) sera effacé du téléphone. Pour '
          "l'allumer à nouveau, il faudra le retélécharger.",
          style: const TextStyle(color: NexusColors.muted, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: NexusColors.muted),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: NexusColors.rose),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await service.remove(ai);
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.phase});

  final AiPhase phase;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (phase) {
      AiPhase.running => ('allumée', NexusColors.mint),
      AiPhase.loading => ('démarrage', NexusColors.violet),
      AiPhase.downloading => ('téléchargement', NexusColors.violet),
      AiPhase.ready => ('téléchargée', NexusColors.muted),
      AiPhase.absent => ('à télécharger', NexusColors.amber),
      AiPhase.failed => ('erreur', NexusColors.rose),
      AiPhase.checking => ('…', NexusColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
