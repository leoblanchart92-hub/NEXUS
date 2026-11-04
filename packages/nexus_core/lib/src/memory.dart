/// Un souvenir : une phrase que Nexus a retenue de son humain.
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

/// Une leçon : un mot et ce qu'il veut dire, retenu en discutant.
class Lesson {
  const Lesson({
    required this.word,
    required this.definition,
    required this.at,
  });

  final String word;
  final String definition;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'at': at.toIso8601String(),
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        word: (json['word'] as String?) ?? '',
        definition: (json['definition'] as String?) ?? '',
        at: DateTime.tryParse((json['at'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// La mémoire de Nexus : des faits sur son humain, des souvenirs et des leçons.
///
/// Elle commence vide à la naissance et se remplit toute seule, au fil des
/// conversations.
class Memory {
  Memory({
    Map<String, String>? facts,
    List<Episode>? episodes,
    Map<String, Lesson>? lessons,
  })  : facts = facts ?? <String, String>{},
        episodes = episodes ?? <Episode>[],
        lessons = lessons ?? <String, Lesson>{};

  /// faits clés/valeurs : `prenom` -> `Léo`, `ville` -> `Lyon`…
  final Map<String, String> facts;

  /// Les souvenirs, du plus ancien au plus récent.
  final List<Episode> episodes;

  /// Les leçons, indexées par mot en minuscules.
  final Map<String, Lesson> lessons;

  static const int maxFacts = 80;
  static const int maxEpisodes = 200;
  static const int maxLessons = 200;

  /// Nombre total de choses retenues.
  int get size => facts.length + episodes.length + lessons.length;

  bool get isEmpty => size == 0;

  String? fact(String key) => facts[key];

  void setFact(String key, String value) {
    final cleanKey = key.trim();
    final cleanValue = value.trim();
    if (cleanKey.isEmpty || cleanValue.isEmpty) return;

    if (facts.length >= maxFacts && !facts.containsKey(cleanKey)) {
      // La mémoire est pleine : on remplace le fait le plus ancien.
      facts.remove(facts.keys.first);
    }
    facts[cleanKey] = cleanValue;
  }

  /// Retient un souvenir, sans doublon avec les dix derniers.
  void remember(String text, DateTime at) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    for (final recent in episodes.reversed.take(10)) {
      if (recent.text.toLowerCase() == clean.toLowerCase()) return;
    }

    episodes.add(Episode(text: clean, at: at));
    while (episodes.length > maxEpisodes) {
      episodes.removeAt(0);
    }
  }

  Episode? latestEpisode() => episodes.isEmpty ? null : episodes.last;

  /// Enregistre une leçon (ou la corrige si le mot existe déjà).
  void learnLesson(String word, String definition, DateTime at) {
    final cleanWord = word.trim();
    final cleanDefinition = definition.trim();
    if (cleanWord.isEmpty || cleanDefinition.isEmpty) return;

    if (lessons.length >= maxLessons && !lessons.containsKey(_key(cleanWord))) {
      lessons.remove(lessons.keys.first);
    }
    lessons[_key(cleanWord)] = Lesson(
      word: cleanWord,
      definition: cleanDefinition,
      at: at,
    );
  }

  Lesson? lessonFor(String word) => lessons[_key(word)];

  /// Les leçons, de la plus ancienne à la plus récente.
  List<Lesson> get lessonList {
    final all = lessons.values.toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return all;
  }

  /// Efface tout ce qu'elle a appris (elle redevient une page blanche).
  void forgetAll() {
    facts.clear();
    episodes.clear();
    lessons.clear();
  }

  String _key(String word) => word.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
        'facts': facts,
        'episodes': [for (final episode in episodes) episode.toJson()],
        'lessons': {
          for (final entry in lessons.entries) entry.key: entry.value.toJson(),
        },
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

    final lessons = <String, Lesson>{};
    final rawLessons = json['lessons'];
    if (rawLessons is Map) {
      rawLessons.forEach((key, value) {
        if (value is Map) {
          lessons[key.toString()] =
              Lesson.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }

    return Memory(facts: facts, episodes: episodes, lessons: lessons);
  }
}
