/// Une IA que Nexus peut télécharger sur le téléphone, puis allumer et
/// éteindre.
///
/// Toutes tournent **en local**, par llama.cpp : une fois le fichier
/// téléchargé, aucune n'a besoin d'Internet pour fonctionner. Les tailles sont
/// les tailles réelles des fichiers publiés sur Hugging Face.
class LocalAi {
  const LocalAi({
    required this.id,
    required this.label,
    required this.tagline,
    required this.url,
    required this.fileName,
    required this.bytes,
    required this.contextTokens,
  });

  /// Identifiant stable, utilisé pour suivre l'état de cette IA.
  final String id;

  /// Nom affiché.
  final String label;

  /// Ce qu'elle change, en une phrase.
  final String tagline;

  /// Adresse du fichier GGUF.
  final String url;

  /// Nom du fichier une fois installé : le moteur s'en sert comme identifiant.
  final String fileName;

  /// Taille du fichier, en octets.
  final int bytes;

  /// Fenêtre de contexte demandée au moteur, en tokens.
  final int contextTokens;

  /// « 1,03 Go » ou « 378 Mo ».
  String get sizeLabel => formatBytes(bytes);
}

/// Écrit une taille en octets de façon lisible : « 512 kio », « 378 Mo »,
/// « 1,03 Go ».
String formatBytes(int bytes) {
  if (bytes >= 1073741824) {
    return '${(bytes / 1073741824).toStringAsFixed(2).replaceAll('.', ',')} Go';
  }
  if (bytes >= 1048576) {
    return '${(bytes / 1048576).round()} Mo';
  }
  return '${(bytes / 1024).round()} kio';
}

const String _qwen3 = 'https://huggingface.co/unsloth';
const String _q4 = 'Q4_K_M.gguf';

/// Les IA proposées, de la plus légère à la plus capable.
const List<LocalAi> aiCatalogue = <LocalAi>[
  LocalAi(
    id: 'qwen3_06b',
    label: 'Qwen3 0.6B',
    tagline: 'Ultra rapide, très peu de mémoire. Réponses courtes et simples.',
    url: '$_qwen3/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-$_q4',
    fileName: 'Qwen3-0.6B-Q4_K_M.gguf',
    bytes: 396705472,
    contextTokens: 2048,
  ),
  LocalAi(
    id: 'qwen3_17b',
    label: 'Qwen3 1.7B',
    tagline: 'Le bon équilibre : rapide et déjà malin. '
        "C'est celle que je conseille pour commencer.",
    url: '$_qwen3/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-$_q4',
    fileName: 'Qwen3-1.7B-Q4_K_M.gguf',
    bytes: 1107409472,
    contextTokens: 2048,
  ),
  LocalAi(
    id: 'qwen3_4b',
    label: 'Qwen3 4B',
    tagline: 'Plus posée, meilleure en raisonnement. Demande un téléphone avec '
        'de la mémoire vive et de la patience.',
    url: '$_qwen3/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-$_q4',
    fileName: 'Qwen3-4B-Q4_K_M.gguf',
    bytes: 2497281312,
    contextTokens: 2048,
  ),
  LocalAi(
    id: 'qwen3_4b_2507',
    label: 'Qwen3 4B Instruct 2507',
    tagline: 'La version la plus récente des gros modèles : la plus juste à '
        "l'écrit, et la plus lente à répondre.",
    url: '$_qwen3/Qwen3-4B-Instruct-2507-GGUF/resolve/main/'
        'Qwen3-4B-Instruct-2507-$_q4',
    fileName: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    bytes: 2497281120,
    contextTokens: 2048,
  ),
];

/// Retrouve une IA par son identifiant.
LocalAi? aiById(String id) {
  for (final LocalAi ai in aiCatalogue) {
    if (ai.id == id) return ai;
  }
  return null;
}
