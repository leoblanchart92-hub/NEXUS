import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_llama/flutter_edge_ai_llama.dart';

import 'ai_catalogue.dart';

/// Où en est une IA sur le téléphone.
enum AiPhase {
  /// On regarde si le fichier est déjà là.
  checking,

  /// Pas encore téléchargée : il n'y a rien à allumer.
  absent,

  /// Le fichier de modèle est en train d'arriver.
  downloading,

  /// Présente sur le téléphone, éteinte.
  ready,

  /// Les poids sont en train de passer en mémoire.
  loading,

  /// Allumée : elle tourne en mémoire, prête à répondre.
  running,

  /// Quelque chose a échoué (mémoire vive, fichier abîmé, réseau…).
  failed,
}

/// L'état d'une IA, tel que l'écran doit l'afficher.
@immutable
class AiState {
  const AiState({this.phase = AiPhase.checking, this.progress, this.error});

  final AiPhase phase;

  /// Avancement du téléchargement, de 0 à 100. `null` s'il est inconnu.
  final double? progress;

  /// Message lisible quand quelque chose s'est mal passé.
  final String? error;
}

/// Le chef d'orchestre des IA locales : il télécharge les fichiers, les allume
/// en mémoire et les éteint.
///
/// Une seule IA tourne à la fois : deux modèles chargés ensemble ne tiennent
/// pas dans la mémoire vive d'un téléphone.
class LocalAiService extends ChangeNotifier {
  final Map<String, AiState> _states = <String, AiState>{};

  bool _engineReady = false;
  bool _busy = false;
  bool _disposed = false;
  String? _activeId;
  InferenceModel? _model;

  /// L'IA allumée, ou `null` si tout est éteint.
  String? get activeId => _activeId;

  /// Vrai pendant un téléchargement, un chargement ou une suppression.
  bool get busy => _busy;

  /// L'état d'une IA (par défaut : on ne sait pas encore).
  AiState stateOf(LocalAi ai) => _states[ai.id] ?? const AiState();

  /// Regarde quelles IA sont déjà sur le téléphone. À appeler au démarrage.
  Future<void> start() async {
    try {
      await _ensureEngine();
      final List<String> installed = await FlutterEdgeAi.listInstalledModels();
      for (final LocalAi ai in aiCatalogue) {
        _states[ai.id] = AiState(
          phase: installed.contains(ai.fileName) ? AiPhase.ready : AiPhase.absent,
        );
      }
    } catch (error) {
      for (final LocalAi ai in aiCatalogue) {
        _states[ai.id] = AiState(
          phase: AiPhase.failed,
          error: _readable(error),
        );
      }
    }
    _notify();
  }

  /// Télécharge le fichier de l'IA sur le téléphone, une fois pour toutes.
  Future<void> download(LocalAi ai) async {
    if (_busy) return;
    _busy = true;
    _set(ai, const AiState(phase: AiPhase.downloading, progress: 0));
    try {
      await _ensureEngine();
      await FlutterEdgeAi.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.gguf,
      )
          .fromNetwork(ai.url)
          .withProgress((Object progress) {
        final double? percent = _percentOf(progress);
        if (percent != null) {
          _set(ai, AiState(phase: AiPhase.downloading, progress: percent));
        }
      }).install();
      _set(ai, const AiState(phase: AiPhase.ready));
    } catch (error) {
      _set(ai, AiState(phase: AiPhase.failed, error: _readable(error)));
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Allume une IA déjà téléchargée : ses poids passent en mémoire.
  Future<void> powerOn(LocalAi ai) async {
    if (_busy) return;
    final AiPhase phase = stateOf(ai).phase;
    if (phase != AiPhase.ready && phase != AiPhase.failed) return;

    _busy = true;
    // On éteint celle qui tournait avant de charger celle-ci.
    await _unload();
    _set(ai, const AiState(phase: AiPhase.loading));
    try {
      await _ensureEngine();
      // Réenregistre le même fichier comme modèle actif : s'il est déjà sur le
      // téléphone, rien n'est retéléchargé.
      await FlutterEdgeAi.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.gguf,
      ).fromNetwork(ai.url).install();
      _model = await FlutterEdgeAi.getActiveModel(maxTokens: ai.contextTokens);
      _activeId = ai.id;
      _set(ai, const AiState(phase: AiPhase.running));
    } catch (error) {
      _activeId = null;
      _set(ai, AiState(phase: AiPhase.ready, error: _readable(error)));
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Éteint une IA : ses poids quittent la mémoire vive. Le fichier reste sur
  /// le téléphone, donc on peut la rallumer sans rien retélécharger.
  Future<void> powerOff(LocalAi ai) async {
    if (_busy) return;
    _busy = true;
    await _unload();
    _set(ai, const AiState(phase: AiPhase.ready));
    _busy = false;
    _notify();
  }

  /// Supprime le fichier du téléphone pour récupérer la place.
  Future<void> remove(LocalAi ai) async {
    if (_busy) return;
    _busy = true;
    if (_activeId == ai.id) {
      await _unload();
    }
    _set(ai, const AiState(phase: AiPhase.checking));
    try {
      await _ensureEngine();
      await FlutterEdgeAi.uninstallModel(ai.fileName);
      _set(ai, const AiState(phase: AiPhase.absent));
    } catch (error) {
      _set(ai, AiState(phase: AiPhase.ready, error: _readable(error)));
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Éteint tout ce qui tourne, sans toucher aux fichiers.
  Future<void> powerOffAll() async {
    if (_busy) return;
    _busy = true;
    await _unload();
    for (final LocalAi ai in aiCatalogue) {
      if (stateOf(ai).phase == AiPhase.running) {
        _set(ai, const AiState(phase: AiPhase.ready));
      }
    }
    _busy = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    final InferenceModel? model = _model;
    _model = null;
    _activeId = null;
    if (model != null) {
      unawaited(model.close().catchError((Object _) {}));
    }
    super.dispose();
  }

  Future<void> _unload() async {
    final InferenceModel? model = _model;
    _model = null;
    _activeId = null;
    if (model == null) return;
    try {
      await model.close();
    } catch (_) {
      // Éteindre une IA déjà éteinte n'est pas une erreur.
    }
  }

  Future<void> _ensureEngine() async {
    if (_engineReady) return;
    await FlutterEdgeAi.initialize(
      inferenceEngines: const <InferenceEngineProvider>[LlamaEngineProvider()],
    );
    _engineReady = true;
  }

  void _set(LocalAi ai, AiState state) {
    _states[ai.id] = state;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Rend une erreur technique lisible par un humain.
  String _readable(Object error) {
    final String raw = error.toString();
    if (raw.contains('memory') || raw.contains('OutOfMemory')) {
      return "Le téléphone n'a pas assez de mémoire vive pour allumer cette "
          'IA. Essaie une plus légère (0.6B ou 1.7B).';
    }
    if (raw.contains('No space') || raw.contains('ENOSPC')) {
      return "Il n'y a plus assez de place sur le téléphone pour ce fichier.";
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'Téléchargement impossible : vérifie ta connexion Internet.';
    }
    if (raw.contains('MissingPluginException')) {
      return "Le moteur local n'est pas disponible sur cet appareil.";
    }
    return raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
  }

  /// Le pourcentage d'avancement, quelle que soit la forme du message reçu.
  double? _percentOf(Object progress) {
    if (progress is num) return progress.toDouble().clamp(0, 100);
    try {
      final dynamic value = progress;
      final Object? candidate =
          value.percent ?? value.percentage ?? value.progress;
      if (candidate is num) return candidate.toDouble().clamp(0, 100);
    } catch (_) {
      // Pas de pourcentage disponible : on garde l'ancien.
    }
    return null;
  }
}
