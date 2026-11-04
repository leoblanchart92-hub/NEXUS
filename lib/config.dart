/// Configuration de l'application.
///
/// La clé de mise à jour n'est jamais stockée dans le dépôt : elle est injectée
/// à la compilation (`--dart-define=NEXUS_UPDATE_KEY=...`) et vient d'un secret
/// GitHub Actions.
class AppConfig {
  /// Version affichée par Nexus, synchronisée avec `pubspec.yaml`.
  static const String version = '0.5.0';
