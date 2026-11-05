import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// La version de Nexus, à garder alignée avec `version:` dans `pubspec.yaml`
/// (un test le vérifie).
const String nexusVersion = '0.10.0';

/// Le manifeste publié avec chaque release. Il contient la version, l'adresse
/// de l'APK, son empreinte SHA-256 et une signature HMAC.
const String updateManifestUrl =
    'https://github.com/leoblanchart92-hub/NEXUS/releases/download/latest/update.json';

/// La clé de signature, fournie à la compilation par la CI
/// (`--dart-define=NEXUS_UPDATE_KEY=…`). Vide sur une compilation locale.
const String _updateKey = String.fromEnvironment('NEXUS_UPDATE_KEY');

/// Le canal natif qui confie l'APK téléchargé au programme d'installation
/// d'Android (voir `MainActivity.kt`).
const MethodChannel _installer = MethodChannel('nexus/installer');

/// Où en est la mise à jour.
enum UpdatePhase {
  /// Rien n'a encore été demandé.
  idle,

  /// On interroge GitHub.
  checking,

  /// L'application est déjà à la dernière version.
  upToDate,

  /// Une version plus récente existe.
  available,

  /// L'APK descend sur le téléphone.
  downloading,

  /// On vérifie l'empreinte du fichier téléchargé.
  verifying,

  /// Android demande à l'utilisateur d'autoriser l'installation.
  needsPermission,

  /// Le programme d'installation d'Android a pris le relais.
  installing,

  /// La vérification ou l'installation a échoué.
  failed,
}

/// Une version de Nexus publiée sur GitHub.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.url,
    required this.sha256,
    required this.notes,
  });

  /// « 0.10.0 ».
  final String version;

  /// Adresse de l'APK signé.
  final String url;

  /// Empreinte SHA-256 de l'APK, en hexadécimal minuscule.
  final String sha256;

  /// Ce que dit la release, en une phrase.
  final String notes;
}

/// Une erreur de mise à jour dont le message est déjà écrit pour l'utilisateur.
class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Compare deux versions « majeure.mineure.correctif ». Renvoie un nombre
/// négatif si [a] est plus ancienne que [b], zéro si elles sont égales.
int compareVersions(String a, String b) {
  final List<int> left = _versionParts(a);
  final List<int> right = _versionParts(b);
  final int length = left.length > right.length ? left.length : right.length;
  for (int i = 0; i < length; i++) {
    final int x = i < left.length ? left[i] : 0;
    final int y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

List<int> _versionParts(String version) {
  return version
      .trim()
      .split('.')
      .map((String part) {
        final String digits = RegExp(r'^\d+').stringMatch(part) ?? '0';
        return int.tryParse(digits) ?? 0;
      })
      .toList(growable: false);
}

/// La signature du manifeste, telle que la CI la fabrique :
/// HMAC-SHA256 de `version|url|sha256`, en hexadécimal.
String signManifest({
  required String key,
  required String version,
  required String url,
  required String sha256,
}) {
  return crypto.Hmac(
    crypto.sha256,
    utf8.encode(key),
  ).convert(utf8.encode('$version|$url|$sha256')).toString();
}

/// Cherche les mises à jour, télécharge l'APK et le fait installer.
///
/// Rien n'est fait sans l'accord de l'utilisateur : la vérification au
/// démarrage est silencieuse, l'installation demande un appui sur le bouton.
class UpdateService extends ChangeNotifier {
  UpdatePhase _phase = UpdatePhase.idle;
  AppUpdate? _update;
  double? _progress;
  String? _error;
  bool _running = false;
  bool _disposed = false;
  HttpClient? _client;

  UpdatePhase get phase => _phase;

  /// La version proposée, quand il y en a une.
  AppUpdate? get update => _update;

  /// Avancement du téléchargement, de 0 à 100 (null si la taille est inconnue).
  double? get progress => _progress;

  /// Le message d'erreur à afficher, s'il y en a un.
  String? get error => _error;

  /// Vrai pendant une vérification, un téléchargement ou une installation.
  bool get busy => _running;

  /// Interroge GitHub, sans rien télécharger.
  Future<void> check() async {
    if (_running) return;
    _running = true;
    _phase = UpdatePhase.checking;
    _error = null;
    _notify();
    try {
      final AppUpdate remote = await _fetchManifest();
      _update = remote;
      _phase = compareVersions(remote.version, nexusVersion) > 0
          ? UpdatePhase.available
          : UpdatePhase.upToDate;
    } catch (error) {
      _phase = UpdatePhase.failed;
      _error = _messageFor(error);
    } finally {
      _running = false;
      _notify();
    }
  }

  /// Télécharge l'APK de la version proposée, vérifie son empreinte, puis
  /// demande à Android de l'installer.
  Future<void> install() async {
    final AppUpdate? remote = _update;
    if (remote == null || _running) return;
    _running = true;
    _error = null;
    try {
      final File apk = await _download(remote);
      await _handToAndroid(apk);
    } catch (error) {
      _phase = UpdatePhase.failed;
      _error = _messageFor(error);
    } finally {
      _running = false;
      _notify();
    }
  }

  /// Ouvre les réglages Android qui autorisent Nexus à installer des APK.
  Future<void> openInstallSettings() async {
    try {
      await _installer.invokeMethod<void>('openInstallSettings');
    } catch (error) {
      _phase = UpdatePhase.failed;
      _error = _messageFor(error);
      _notify();
    }
  }

  Future<AppUpdate> _fetchManifest() async {
    final HttpClient client = _newClient();
    try {
      // Le paramètre final évite de relire un manifeste gardé en cache par le
      // CDN de GitHub après la publication d'une nouvelle version.
      final Uri uri = Uri.parse(
        '$updateManifestUrl?n=${DateTime.now().millisecondsSinceEpoch}',
      );
      final HttpClientRequest request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Nexus/$nexusVersion');
      final HttpClientResponse response = await request
          .close()
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw const UpdateException(
          'Aucune mise à jour publiée pour le moment.',
        );
      }
      final String body = await utf8.decoder.bind(response).join();
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const UpdateException('Le manifeste de mise à jour est illisible.');
      }

      final AppUpdate candidate = AppUpdate(
        version: '${decoded['version'] ?? ''}'.trim(),
        url: '${decoded['url'] ?? ''}'.trim(),
        sha256: '${decoded['sha256'] ?? ''}'.trim().toLowerCase(),
        notes: '${decoded['notes'] ?? ''}'.trim(),
      );
      if (candidate.version.isEmpty ||
          candidate.url.isEmpty ||
          candidate.sha256.length != 64) {
        throw const UpdateException('Le manifeste de mise à jour est incomplet.');
      }

      final String signature = '${decoded['signature'] ?? ''}'
          .trim()
          .toLowerCase();
      if (_updateKey.isNotEmpty) {
        final String expected = signManifest(
          key: _updateKey,
          version: candidate.version,
          url: candidate.url,
          sha256: candidate.sha256,
        );
        if (signature != expected) {
          throw const UpdateException(
            "La mise à jour ne porte pas la bonne signature : elle n'est pas "
            'installée.',
          );
        }
      }
      return candidate;
    } on UpdateException {
      rethrow;
    } catch (error) {
      throw const UpdateException(
        "Impossible de joindre GitHub pour vérifier les mises à jour.",
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<File> _download(AppUpdate remote) async {
    _phase = UpdatePhase.downloading;
    _progress = 0;
    _notify();

    final Directory support = await getApplicationSupportDirectory();
    final Directory folder = Directory('${support.path}/updates');
    await folder.create(recursive: true);
    final File apk = File('${folder.path}/nexus-${remote.version}.apk');
    if (await apk.exists()) {
      await apk.delete();
    }

    final HttpClient client = _newClient();
    IOSink? sink;
    try {
      final HttpClientRequest request = await client.getUrl(
        Uri.parse(remote.url),
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'Nexus/$nexusVersion');
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw const UpdateException(
          "Le serveur n'a pas voulu envoyer l'APK. Réessaie plus tard.",
        );
      }

      final int total = response.contentLength;
      crypto.Digest? digest;
      final ByteConversionSink hasher = crypto.sha256.startChunkedConversion(
        ChunkedConversionSink<crypto.Digest>.withCallback(
          (List<crypto.Digest> digests) => digest = digests.last,
        ),
      );
      int received = 0;
      int lastPercent = 0;

      sink = apk.openWrite();
      await for (final List<int> chunk in response) {
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final int percent = (received * 100 ~/ total).clamp(0, 100);
          if (percent != lastPercent) {
            lastPercent = percent;
            _progress = percent.toDouble();
            _notify();
          }
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      hasher.close();

      _phase = UpdatePhase.verifying;
      _notify();

      final String actual = (digest?.toString() ?? '').toLowerCase();
      if (actual != remote.sha256) {
        await apk.delete();
        throw const UpdateException(
          "Le fichier téléchargé est abîmé : il a été supprimé, réessaie.",
        );
      }
      return apk;
    } catch (error) {
      if (sink != null) {
        await sink.close();
        sink = null;
      }
      if (await apk.exists()) {
        await apk.delete();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _handToAndroid(File apk) async {
    final bool allowed =
        await _installer.invokeMethod<bool>('canInstall') ?? false;
    if (!allowed) {
      await _installer.invokeMethod<void>('openInstallSettings');
      _phase = UpdatePhase.needsPermission;
      return;
    }
    await _installer.invokeMethod<void>('install', <String, String>{
      'path': apk.path,
    });
    _phase = UpdatePhase.installing;
  }

  HttpClient _newClient() {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    _client = client;
    return client;
  }

  String _messageFor(Object error) {
    if (error is UpdateException) return error.message;
    if (error is SocketException) {
      return 'Pas de connexion : réessaie quand tu as du réseau.';
    }
    if (error is TimeoutException) {
      return 'GitHub ne répond pas. Réessaie dans un moment.';
    }
    if (error is HandshakeException) {
      return 'La connexion sécurisée a échoué : réessaie en Wi-Fi.';
    }
    if (error is MissingPluginException) {
      return "L'installation automatique n'existe pas sur cette version de "
          "l'application : télécharge l'APK depuis GitHub.";
    }
    if (error is PlatformException) {
      return error.message ?? "Android a refusé d'installer la mise à jour.";
    }
    if (error is FileSystemException) {
      return "Impossible d'écrire l'APK sur le téléphone : vérifie l'espace "
          'libre.';
    }
    return "La mise à jour a échoué. Réessaie dans un moment.";
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _client?.close(force: true);
    _client = null;
    super.dispose();
  }
}
