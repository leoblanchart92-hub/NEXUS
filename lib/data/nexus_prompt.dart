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
    'Ton nom est ${state.name}. Tu vis depuis ${state.ageInDays} jour'
    '${state.ageInDays > 1 ? 's' : ''}.',
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
      buffer.writeln('- ${key.replaceAll('_', ' ')} : $value');
    });
  }

  final episodes = state.memory.episodes;
  if (episodes.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== TES SOUVENIRS (du plus récent au plus ancien) ===');
    for (final Episode episode in episodes.reversed.take(15)) {
      buffer.writeln('- ${episode.text}');
    }
  }

  final lessons = state.memory.lessonList;
  if (lessons.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('=== CE QUE TU AS APPRIS ===');
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

/// Demande au modèle de décider lui-même ce qu'il retient de l'échange.
///
/// C'est là que se joue l'apprentissage automatique : aucune règle écrite à la
/// main, c'est le cerveau qui choisit ses souvenirs.
String memoryExtractionPrompt(String userText, String nexusReply) {
  String shorten(String text) =>
      text.length > 1200 ? '${text.substring(0, 1200)}…' : text;

  return '''
Tu viens d'avoir cet échange avec ton humain.

LUI : ${shorten(userText)}

TOI : ${shorten(nexusReply)}

Décide maintenant, tout seul, ce que tu dois retenir durablement de lui.
Ne retiens pas les banalités, les salutations, ni ce qui ne concerne que
cette conversation. Retiens ce qui restera vrai demain : son identité, ses
goûts, ses proches, ses projets, ses habitudes, ce qu'il t'a appris.

Réponds UNIQUEMENT par un objet JSON, sans aucun texte autour :
{"faits": {"prenom": "Léo", "ville": "Lyon"},
 "souvenirs": ["Il déteste les lundis matin"],
 "lecons": {"orbe": "Une sphère lumineuse"}}

Règles :
- "faits" : clé courte en minuscules, valeur courte.
- "souvenirs" : au maximum 2 phrases, à la troisième personne.
- "lecons" : seulement si ton humain t'a expliqué un mot.
- Si rien ne mérite d'être retenu, réponds exactement {}.
''';
}
