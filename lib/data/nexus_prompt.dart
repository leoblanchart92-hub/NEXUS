import 'package:nexus_core/nexus_core.dart';

/// Construit le contexte envoyé au modèle neuronal à chaque tour de parole :
/// sa personnalité, ce qu'elle sait de son humain, ses souvenirs et ses leçons.
///
/// Rien n'est inventé ici : tout vient de l'état réel de Nexus. C'est ce bloc
/// qui fait qu'elle « se souvient » et qu'elle obéit aux règles de son humain,
/// puisque le modèle, lui, a des poids gelés.
String buildPromptContext(
  NexusState state, {
  List<String> recentTurns = const <String>[],
  int maxChars = 2200,
}) {
  final buffer = StringBuffer();

  buffer.writeln('=== QUI TU ES ===');
  buffer.writeln(
    'Ton nom est ${state.name}. Tu as ${state.ageInDays} jour'
    '${state.ageInDays > 1 ? 's' : ''} de vie. '
    'Ton stade de croissance : ${state.stage.label}. '
    'Ton état intérieur en ce moment : ${state.needs.mood}.',
  );

  final rules = state.persona.trim();
  if (rules.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== LES RÈGLES DE TON HUMAIN (tu leur obéis) ===');
    buffer.writeln(rules);
  }

  final facts = state.memory.facts;
  if (facts.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== CE QUE TU SAIS DE LUI ===');
    facts.forEach((String key, String value) {
      final label = key.startsWith('user.') ? key.substring(5) : key;
      buffer.writeln('- $label : $value');
    });
  }

  final episodes = state.memory.episodes;
  if (episodes.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== TES SOUVENIRS (du plus récent au plus ancien) ===');
    for (final Episode episode in episodes.reversed.take(12)) {
      buffer.writeln('- ${episode.text}');
    }
  }

  final lessons = state.memory.lessonList;
  if (lessons.isNotEmpty) {
    buffer.writeln();
    buffer.writeln("=== CE QU'IL T'A APPRIS (tu le sais vraiment) ===");
    for (final Lesson lesson in lessons.reversed.take(30)) {
      buffer.writeln('- ${lesson.word} : ${lesson.definition}');
    }
  }

  if (recentTurns.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== VOTRE CONVERSATION JUSTE AVANT ===');
    for (final String turn in recentTurns) {
      buffer.writeln(turn);
    }
  }

  buffer.writeln();
  buffer.writeln('=== MAINTENANT ===');
  buffer.writeln(
    "Ton humain vient de t'écrire ci-dessous. Réponds-lui directement, en "
    'français, en te servant de tout ce qui précède. Ne récite pas ce '
    "contexte et n'invente aucun souvenir.",
  );

  final text = buffer.toString();
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars)}\n'
      '[contexte tronqué : ta mémoire est plus grande que ta fenêtre de '
      'parole actuelle]';
}
