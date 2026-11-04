/// Un souvenir : une phrase que son parent lui a demandé de retenir.
class Episode {
  const Episode({required this.text, required this.at});

  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'text': text,
        'at': at.toIso8601String(),
      };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        text: (json['text'] as String?) ?? '',
        at: DateTime.tryParse((json['at'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// La mémoire de Nexus : des faits sur son parent et des souvenirs.
class Memory {
  Memory({Map<String, String>? facts, List<Episode>? episodes})
      : facts = facts ?? <String, String>{},
        episodes = episodes ?? <Episode>[];

  /// faits clés/valeurs, par exemple `user.name` -> `Léo`.
  final Map<String, String> facts;

  /// Les souvenirs, du plus ancien au plus récent.
  final List<Episode> episodes;

  static const int maxEpisodes = 120;

  String? fact(String key) => facts[key];

  void setFact(String key, String value) {
    facts[key] = value;
  }

  void remember(String text, DateTime at) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    episodes.add(Episode(text: clean, at: at));
    while (episodes.length > maxEpisodes) {
      episodes.removeAt(0);
    }
  }

  Episode? latestEpisode() => episodes.isEmpty ? null : episodes.last;

  Map<String, dynamic> toJson() => {
        'facts': facts,
        'episodes': [for (final episode in episodes) episode.toJson()],
      };

  factory Memory.fromJson(Map<String, dynamic> json) {
    final facts = <String, String>{};
    final rawFacts = json['facts'];
    if (rawFacts is Map) {
      rawFacts.forEach((key, value) {
        facts[key.toString()] = value.toString();
      });
    }

    final episodes = <Episode>[];
    final rawEpisodes = json['episodes'];
    if (rawEpisodes is List) {
      for (final raw in rawEpisodes) {
        if (raw is Map) {
          episodes.add(Episode.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return Memory(facts: facts, episodes: episodes);
  }
}
