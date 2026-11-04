/// Un cerveau que Nexus peut installer et allumer.
///
/// Tous tournent **en local**, sur le téléphone, par llama.cpp : aucun n'a
/// besoin d'Internet pour répondre. Les tailles sont les tailles réelles des
/// fichiers publiés sur Hugging Face.
class BrainVariant {
  const BrainVariant({
    required this.id,
    required this.label,
    required this.tagline,
    required this.url,
    required this.fileName,
    required this.bytes,
    required this.contextTokens,
  });

  /// Identifiant stable, utilisé pour se souvenir du cerveau allumé.
  final String id;

  /// Nom affiché.
  final String label;

  /// Ce qu'il change, en une phrase.
  final String tagline;

  /// Adresse du fichier GGUF.
  final String url;

  /// Nom du fichier une fois installé (le moteur s'en sert comme identifiant).
  final String fileName;

  /// Taille du fichier, en octets.
  final int bytes;

  /// Fenêtre de contexte demandée au moteur.
  final int contextTokens;

  /// « 1,03 Go » ou « 378 Mo ».
  String get sizeLabel {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2).replaceAll('.', ',')} Go';
    }
    return '${(bytes / 1048576).round()} Mo';
  }
}

const String _qwen3 = 'https://huggingface.co/unsloth';
const String _q4 = 'Q4_K_M.gguf';

/// Les quatre cerveaux proposés, du plus léger au plus capable.
const List<BrainVariant> brainCatalogue = <BrainVariant>[
  BrainVariant(
    id: 'qwen3_06b',
    label: 'Qwen3 0.6B',
    tagline: 'Ultra rapide, très peu de mémoire. Réponses courtes et simples.',
    url: '$_qwen3/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-$_q4',
    fileName: 'Qwen3-0.6B-Q4_K_M.gguf',
    bytes: 396705472,
    contextTokens: 2048,
  ),
  BrainVariant(
    id: 'qwen3_17b',
    label: 'Qwen3 1.7B',
    tagline: 'Le bon équilibre : rapide et déjà malin. C\'est celui que je '
        'conseille pour commencer.',
    url: '$_qwen3/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-$_q4',
    fileName: 'Qwen3-1.7B-Q4_K_M.gguf',
    bytes: 1107409472,
    contextTokens: 2048,
  ),
  BrainVariant(
    id: 'qwen3_4b',
    label: 'Qwen3 4B',
    tagline: 'Plus posé, meilleur en raisonnement. Demande un téléphone avec '
        'de la mémoire vive et de la patience.',
    url: '$_qwen3/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-$_q4',
    fileName: 'Qwen3-4B-Q4_K_M.gguf',
    bytes: 2497281312,
    contextTokens: 2048,
  ),
  BrainVariant(
    id: 'qwen3_4b_2507',
    label: 'Qwen3 4B Instruct 2507',
    tagline: 'La version la plus récente des gros modèles : le plus juste à '
        'l\'écrit, et le plus lent à répondre.',
    url: '$_qwen3/Qwen3-4B-Instruct-2507-GGUF/resolve/main/'
        'Qwen3-4B-Instruct-2507-$_q4',
    fileName: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    bytes: 2497281120,
    contextTokens: 2048,
  ),
];

/// Le cerveau proposé par défaut la première fois.
BrainVariant get defaultBrain => brainCatalogue[1];

/// Retrouve un cerveau par son identifiant.
BrainVariant? brainById(String id) {
  for (final BrainVariant brain in brainCatalogue) {
    if (brain.id == id) return brain;
  }
  return null;
}

/// Retrouve un cerveau à partir du nom de fichier installé sur le téléphone.
BrainVariant? brainByFileName(String fileName) {
  for (final BrainVariant brain in brainCatalogue) {
    if (brain.fileName == fileName) return brain;
  }
  return null;
}
