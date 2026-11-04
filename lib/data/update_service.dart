import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

/// Le manifeste publié avec chaque build.
///
/// Il est signé : sans la clé de mise à jour, impossible d'en fabriquer un
/// faux qui soit accepté par l'application.
class UpdateManifest {
  const UpdateManifest({
    required this.version,
    required this.url,
    required this.sha256,
    required this.notes,
    required this.signature,
  });

  final String version;
  final String url;
  final String sha256;
  final String notes;
  final String signature;

  /// La chaîne effectivement signée par le serveur de build.
  String get signedPayload => '$version|$url|$sha256';

  factory UpdateManifest.fromJson(Map<String, dynamic> json) => UpdateManifest(
        version: json['version']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        sha256: json['sha256']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        signature: json['signature']?.toString() ?? '',
      );
}

enum UpdateStatus {
  /// Aucune clé n'a été compilée dans cette version.
  locked,

  /// Le manifeste est signé, mais l'application est déjà à jour.
  upToDate,

  /// Une version plus récente est disponible et authentifiée.
  available,

  /// Le manifeste est présent mais sa signature est fausse.
  invalid,

  /// Impossible de joindre le serveur de mise à jour.
  failed,
}

class UpdateCheck {
  const UpdateCheck(this.status, this.message, {this.manifest});

  final UpdateStatus status;
  final String message;
  final UpdateManifest? manifest;

  bool get hasUpdate => status == UpdateStatus.available;
}

/// Une mise à jour qui échoue, avec une raison lisible par son humain.
class UpdateException implements Exception {
  UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Vérifie, télécharge et installe les mises à jour signées en HMAC-SHA256.
///
/// Le principe : une mise à jour n'est proposée que si la signature correspond
/// à la clé. Sans la clé, l'application refuse tout manifeste, même valide.
/// Ensuite, l'APK téléchargé doit avoir exactement l'empreinte annoncée par le
/// manifeste, sinon il est supprimé : un fichier altéré en route ne peut pas
/// être installé.
class UpdateService {
  UpdateService({
    this.manifestUrl = AppConfig.updateManifestUrl,
    String? key,
    this.currentVersion = AppConfig.version,
  }) : key = key ?? AppConfig.updateKey;

  final String manifestUrl;
  final String key;
  final String currentVersion;

  /// Le canal natif qui confie l'APK au programme d'installation d'Android.
  static const MethodChannel _installer = MethodChannel('nexus/installer');

  bool get isUnlocked => key.isNotEmpty;

  /// Vérifie la signature du manifeste en temps constant.
  bool verifySignature(UpdateManifest manifest) {
    if (!isUnlocked) return false;

    final expected = Hmac(sha256, utf8.encode(key))
        .convert(utf8.encode(manifest.signedPayload))
        .toString();
    return _constantTimeEquals(expected, manifest.signature.toLowerCase());
  }

  Future<UpdateCheck> check() async {
    if (!isUnlocked) {
      return const UpdateCheck(
        UpdateStatus.locked,
        "Mises à jour verrouillées : cette version n'a pas de clé.",
      );
    }

    try {
      final raw = await _fetch(manifestUrl);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const UpdateCheck(
          UpdateStatus.invalid,
          'Manifeste de mise à jour illisible.',
        );
      }

      final manifest =
          UpdateManifest.fromJson(Map<String, dynamic>.from(decoded));
      if (!verifySignature(manifest)) {
        return const UpdateCheck(
          UpdateStatus.invalid,
          'Signature invalide : mise à jour refusée.',
        );
      }

      if (!_isNewer(manifest.version, currentVersion)) {
        return UpdateCheck(
          UpdateStatus.upToDate,
          'Tu es à jour ($currentVersion).',
          manifest: manifest,
        );
      }

      return UpdateCheck(
        UpdateStatus.available,
        'Version ${manifest.version} disponible.',
        manifest: manifest,
      );
    } catch (error) {
      return UpdateCheck(
        UpdateStatus.failed,
        'Vérification impossible : $error',
      );
    }
  }

  /// Télécharge l'APK signé, contrôle son empreinte SHA-256 et le garde sur le
  /// téléphone jusqu'à l'installation.
  ///
  /// [onProgress] reçoit une valeur entre 0 et 1.
  Future<File> downloadApk(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    if (manifest.sha256.isEmpty) {
      throw UpdateException("Le manifeste ne donne pas d'empreinte.");
    }

    final directory = await _updateDirectory();
    final target = File('${directory.path}/nexus-${manifest.version}.apk');
    if (target.existsSync()) {
      await target.delete();
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    IOSink? sink;

    try {
      final request = await client.getUrl(Uri.parse(manifest.url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException(
          'Téléchargement refusé (HTTP ${response.statusCode}).',
        );
      }

      final total = response.contentLength;
      var received = 0;
      sink = target.openWrite();
      await for (final List<int> chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (received == 0) {
        throw UpdateException('Le fichier reçu est vide.');
      }

      final digest = await sha256.bind(target.openRead()).first;
      if (digest.toString().toLowerCase() != manifest.sha256.toLowerCase()) {
        await target.delete();
        throw UpdateException(
          'Empreinte incorrecte : le fichier a été altéré, il est refusé.',
        );
      }

      onProgress?.call(1);
      return target;
    } on UpdateException {
      rethrow;
    } catch (error) {
      if (target.existsSync()) {
        await target.delete();
      }
      throw UpdateException('Téléchargement impossible : $error');
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }

  /// Android 8+ exige une autorisation explicite avant d'installer un APK
  /// téléchargé hors magasin.
  Future<bool> canInstallPackages() async {
    try {
      return await _installer.invokeMethod<bool>('canInstall') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre l'écran système qui autorise Nexus à installer ses mises à jour.
  Future<bool> requestInstallPermission() async {
    try {
      return await _installer.invokeMethod<bool>('openInstallSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Confie l'APK au programme d'installation d'Android.
  Future<bool> installApk(File apk) async {
    try {
      final opened =
          await _installer.invokeMethod<bool>('install', <String, dynamic>{
        'path': apk.path,
      });
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre la page de téléchargement de l'APK signé.
  Future<bool> openDownload(UpdateManifest manifest) async {
    final uri = Uri.tryParse(manifest.url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Ouvre la page des releases (utile si le manifeste est absent).
  Future<bool> openReleases() async {
    final uri = Uri.tryParse(AppConfig.releasesUrl);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<Directory> _updateDirectory() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/updates');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> _fetch(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  bool _isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  List<int> _parts(String version) {
    final cleaned = version.split('+').first.split('-').first;
    final numbers = cleaned.split('.').map(int.tryParse).toList();
    return [
      for (var i = 0; i < 3; i++)
        (i < numbers.length ? numbers[i] : null) ?? 0,
    ];
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
