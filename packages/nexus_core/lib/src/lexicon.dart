import 'dart:math';

/// Vrai pour les caractères qui font partie d'un mot (lettres latines,
/// chiffres, accents français). Tout le reste sépare les mots.
bool _isWordRune(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return true; // 0-9
  if (rune >= 0x61 && rune <= 0x7A) return true; // a-z
  if (rune == 0xD7 || rune == 0xF7) return false; // × et ÷
  if (rune >= 0xC0 && rune <= 0x24F) return true; // latin étendu (é, à, ç, œ…)
  return false;
}

/// Découpe un texte en mots normalisés.
///
/// Les apostrophes et tirets séparent les mots : `m'appelle` donne
/// `['m', 'appelle']`. Les mots d'une seule lettre sont ignorés.
List<String> tokenize(String input) {
  final words = <String>[];
  final buffer = StringBuffer();

  for (final rune in input.toLowerCase().runes) {
    if (_isWordRune(rune)) {
      buffer.writeCharCode(rune);
    } else if (buffer.isNotEmpty) {
      words.add(buffer.toString());
      buffer.clear();
    }
  }
  if (buffer.isNotEmpty) words.add(buffer.toString());

  return words.where((word) => word.length > 1).toList(growable: false);
}

/// Le vocabulaire de Nexus : les mots qu'il a entendus, les enchaînements
/// entre ces mots, et les syllabes qu'il a retenues pour babiller.
class Lexicon {
  Lexicon({
    Map<String, int>? words,
    Map<String, Map<String, int>>? transitions,
    Set<String>? syllables,
  })  : words = words ?? <String, int>{},
        transitions = transitions ?? <String, Map<String, int>>{},
        syllables = syllables ?? <String>{};

  /// mot -> nombre de fois entendu.
  final Map<String, int> words;

  /// mot -> (mot suivant -> nombre de fois).
  final Map<String, Map<String, int>> transitions;

  /// Syllabes tirées des mots entendus, utilisées pour babiller.
  final Set<String> syllables;

  int get size => words.length;

  static const int maxWords = 4000;
  static const int maxSyllables = 80;

  bool contains(String word) => words.containsKey(word);

  int countOf(String word) => words[word] ?? 0;

  /// Les mots les plus entendus, du plus fréquent au moins fréquent.
  List<String> get topWords {
    final entries = words.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final entry in entries) entry.key];
  }

  /// Absorbe une phrase entendue.
  void learn(List<String> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final word = tokens[i];
      if (words.length >= maxWords && !words.containsKey(word)) continue;
      words[word] = (words[word] ?? 0) + 1;
      _harvestSyllable(word);

      if (i + 1 < tokens.length) {
        final next = tokens[i + 1];
        final branch = transitions.putIfAbsent(word, () => <String, int>{});
        branch[next] = (branch[next] ?? 0) + 1;
      }
    }
  }

  void _harvestSyllable(String word) {
    if (syllables.length >= maxSyllables || word.length < 3) return;
    final length = min(3, word.length);
    syllables.add(word.substring(0, length));
  }

  /// Le mot qui suit le plus probablement [word].
  String? nextAfter(String word, Random random) {
    final branch = transitions[word];
    if (branch == null || branch.isEmpty) return null;
    return _weightedPick(branch, random);
  }

  /// Un mot au hasard, pondéré par la fréquence.
  String? randomWord(Random random) {
    if (words.isEmpty) return null;
    return _weightedPick(words, random);
  }

  String? _weightedPick(Map<String, int> pool, Random random) {
    var total = 0;
    for (final weight in pool.values) {
      total += weight;
    }
    if (total <= 0) return null;

    var roll = random.nextInt(total);
    for (final entry in pool.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return pool.keys.last;
  }

  Map<String, dynamic> toJson() => {
        'words': words,
        'transitions': transitions,
        'syllables': syllables.toList(),
      };

  factory Lexicon.fromJson(Map<String, dynamic> json) {
    final words = <String, int>{};
    final rawWords = json['words'];
    if (rawWords is Map) {
      rawWords.forEach((key, value) {
        if (value is num) words[key.toString()] = value.toInt();
      });
    }

    final transitions = <String, Map<String, int>>{};
    final rawTransitions = json['transitions'];
    if (rawTransitions is Map) {
      rawTransitions.forEach((key, value) {
        if (value is Map) {
          final branch = <String, int>{};
          value.forEach((next, count) {
            if (count is num) branch[next.toString()] = count.toInt();
          });
          transitions[key.toString()] = branch;
        }
      });
    }

    final syllables = <String>{};
    final rawSyllables = json['syllables'];
    if (rawSyllables is List) {
      for (final syllable in rawSyllables) {
        syllables.add(syllable.toString());
      }
    }

    return Lexicon(
      words: words,
      transitions: transitions,
      syllables: syllables,
    );
  }
}
