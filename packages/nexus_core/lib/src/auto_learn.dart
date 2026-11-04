import 'dart:convert';

import 'memory.dart';

/// Ce que Nexus décide de retenir après une conversation.
///
/// C'est le modèle lui-même qui produit ces éléments, sous forme de JSON, à
/// la fin de chaque échange. Ici on ne fait que le lire proprement : un modèle
/// de 1,7 milliard de paramètres écrit souvent du JSON imparfait.
class MemoryUpdate {
  const MemoryUpdate({
    this.facts = const <String, String>{},
    this.episodes = const <String>[],
    this.lessons = const <String, String>{},
  });

  final Map<String, String> facts;
  final List<String> episodes;
  final Map<String, String> lessons;

  bool get isEmpty => facts.isEmpty && episodes.isEmpty && lessons.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get size => facts.length + episodes.length + lessons.length;

  /// Lit la sortie du modèle. Renvoie `null` si rien d'exploitable.
  static MemoryUpdate? fromModelOutput(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(raw.substring(start, end + 1));
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    final facts = <String, String>{};
    final episodes = <String>[];
    final lessons = <String, String>{};

    _readPairs(
      decoded['faits'] ?? decoded['facts'] ?? decoded['souvenirs_utiles'],
      facts,
    );
    _readEpisodes(decoded['souvenirs'] ?? decoded['episodes'], episodes);
    _readPairs(
      decoded['lecons'] ?? decoded['leçons'] ?? decoded['lessons'],
      lessons,
    );

    final update = MemoryUpdate(
      facts: facts,
      episodes: episodes,
      lessons: lessons,
    );
    return update.isEmpty ? null : update;
  }

  /// Écrit ce que le modèle a retenu dans la mémoire de Nexus.
  void applyTo(Memory memory, {DateTime? at}) {
    final moment = at ?? DateTime.now();
    facts.forEach(memory.setFact);
    for (final String text in episodes) {
      memory.remember(text, moment);
    }
    lessons.forEach((String word, String definition) {
      memory.learnLesson(word, definition, moment);
    });
  }

  static void _readPairs(Object? source, Map<String, String> target) {
    if (source is Map) {
      source.forEach((key, value) {
        final cleanKey = _cleanKey(key);
        final cleanValue = _cleanValue(value);
        if (cleanKey != null && cleanValue != null) {
          target[cleanKey] = cleanValue;
        }
      });
      return;
    }
    if (source is List) {
      // Format possible : ["prenom: Léo", "ville: Lyon"]
      for (final item in source) {
        final text = _cleanValue(item);
        if (text == null) continue;
        final separator = text.indexOf(':');
        if (separator <= 0) continue;
        final key = _cleanKey(text.substring(0, separator));
        final value = _cleanValue(text.substring(separator + 1));
        if (key != null && value != null) target[key] = value;
      }
    }
  }

  static void _readEpisodes(Object? source, List<String> target) {
    if (source is List) {
      for (final item in source) {
        final text = _cleanValue(item);
        if (text != null) target.add(text);
      }
      return;
    }
    if (source is Map) {
      for (final value in source.values) {
        final text = _cleanValue(value);
        if (text != null) target.add(text);
      }
    }
  }

  static String? _cleanKey(Object? key) {
    final text = _cleanValue(key);
    if (text == null) return null;
    final clean = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\wàâäéèêëîïôöùûüç ]"), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return clean.isEmpty ? null : clean;
  }

  static String? _cleanValue(Object? value) {
    if (value == null) return null;
    final text = value is String ? value : value.toString();
    var clean = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    if (clean.length >= 2 &&
        ((clean.startsWith('"') && clean.endsWith('"')) ||
            (clean.startsWith("'") && clean.endsWith("'")))) {
      clean = clean.substring(1, clean.length - 1).trim();
    }
    if (clean.length < 2) return null;
    if (clean.toLowerCase() == 'null' || clean.toLowerCase() == 'aucun') {
      return null;
    }
    return clean.length > 240 ? '${clean.substring(0, 240)}…' : clean;
  }
}
