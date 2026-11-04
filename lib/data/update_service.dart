import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

/// Vérifie les mises à jour à partir d'un manifeste signé par HMAC-SHA256.
///
/// Le principe : une mise à jour n'est proposée que si la signature correspond
/// à la clé. Sans la clé, l'application refuse tout manifeste, même valide.
class UpdateService {
  UpdateService({
    this.manifestUrl = AppConfig.updateManifestUrl,
    String? key,
    this.currentVersion = AppConfig.version,
  }) : key = key ?? AppConfig.updateKey;

  final String manifestUrl;
  final String key;
  final String currentVersion;

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

      final manifest = UpdateManifest.fromJson(Map<String, dynamic>.from(decoded));
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
