/// Configuration de l'application.
///
/// La clé de mise à jour n'est jamais stockée dans le dépôt : elle est injectée
/// à la compilation (`--dart-define=NEXUS_UPDATE_KEY=...`) et vient d'un secret
/// GitHub Actions.
class AppConfig {
  /// Version affichée par Nexus, synchronisée avec `pubspec.yaml`.
  static const String version = '0.5.1';

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

  /// Le cerveau : Qwen3-1.7B quantifié (Q4_K_M), un vrai réseau de neurones
  /// qui tourne en local avec llama.cpp. Téléchargé une seule fois, puis
  /// exécuté hors ligne, sans aucune connexion ni compte.
  static const String brainUrl =
      'https://huggingface.co/unsloth/Qwen3-1.7B-GGUF/resolve/main/'
      'Qwen3-1.7B-Q4_K_M.gguf';

  /// Nom sous lequel le fichier est installé sur le téléphone.
  static const String brainFile = 'Qwen3-1.7B-Q4_K_M.gguf';

  /// Taille annoncée du fichier, en octets (1,03 Gio).
  static const int brainBytes = 1107409472;

  /// Fenêtre de contexte : assez pour la personnalité, la mémoire et la
  /// conversation en cours, sans faire exploser la mémoire vive du téléphone.
  static const int contextTokens = 2048;
}
