/// Configuration de l'application.
///
/// La clé de mise à jour n'est jamais stockée dans le dépôt : elle est injectée
/// à la compilation (`--dart-define=NEXUS_UPDATE_KEY=...`) et vient d'un secret
/// GitHub Actions.
class AppConfig {
  /// Version affichée par Nexus, synchronisée avec `pubspec.yaml`.
  static const String version = '0.2.0';

  static const String owner = 'leoblanchart92-hub';
  static const String repository = 'NEXUS';
  static const String repoUrl = 'https://github.com/$owner/$repository';

  /// Manifeste de mise à jour, publié en tant qu'asset de la release `latest`.
  static const String updateManifestUrl =
      'https://github.com/$owner/$repository/releases/download/latest/update.json';

  /// Page de téléchargement si le manifeste ne peut pas être lu.
  static const String releasesUrl = '$repoUrl/releases/latest';

  /// Clé de mise à jour. Vide = mises à jour verrouillées.
  static const String updateKey = String.fromEnvironment('NEXUS_UPDATE_KEY');

  static bool get updatesUnlocked => updateKey.isNotEmpty;
}
