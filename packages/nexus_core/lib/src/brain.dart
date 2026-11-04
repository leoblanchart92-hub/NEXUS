import 'dart:math';

import 'lexicon.dart';
import 'memory.dart';
import 'stage.dart';
import 'state.dart';

/// Ce que Nexus vient d'apprendre pendant un échange.
enum LearnedKind { nexusName, parentName, preference, souvenir }

class LearnedFact {
  const LearnedFact(this.kind, this.value);

  final LearnedKind kind;
  final String value;
}

/// Une réponse de Nexus, avec de quoi raconter sa croissance à l'écran.
class NexusReply {
  const NexusReply({
    required this.text,
    required this.stage,
    required this.stageUp,
    required this.newWords,
    required this.learned,
    required this.mood,
  });

  final String text;
  final Stage stage;
  final bool stageUp;
  final List<String> newWords;
  final LearnedFact? learned;
  final String mood;
}

/// Mots vides : ils ne servent pas à désigner une chose précise.
const Set<String> _stopwords = {
  'le', 'la', 'les', 'des', 'du', 'de', 'un', 'une', 'et', 'ou', 'au', 'aux',
  'ce', 'ces', 'cet', 'cette', 'dans', 'sur', 'pour', 'avec', 'sans', 'chez',
  'je', 'tu', 'il', 'elle', 'on', 'nous', 'vous', 'ils', 'elles', 'moi', 'toi',
  'lui', 'leur', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'son', 'sa', 'ses',
  'est', 'suis', 'es', 'sont', 'etre', 'être', 'ai', 'as', 'avons', 'avez',
  'ont', 'pas', 'plus', 'tres', 'très', 'trop', 'bien', 'tout', 'tous', 'toute',
  'que', 'qui', 'quoi', 'dont', 'car', 'donc', 'mais', 'si', 'ne', 'y', 'en',
};

/// Le cerveau de Nexus.
///
/// Il ne contient aucun modèle pré-entraîné : il naît littéralement vide.
/// Il apprend les mots qu'on lui dit, retient les faits importants, puis
/// recompose ce qu'il a entendu. Plus il grandit, plus ses phrases
/// s'allongent.
class NexusBrain {
  NexusBrain({NexusState? state, int seed = 2026})
      : state = state ?? NexusState(name: 'Nexus'),
        _random = Random(seed);

  final NexusState state;
  final Random _random;

  static const List<String> _onsets = [
    'b', 'd', 'm', 'p', 't', 'n', 'k', 'g', 'l', 'v', 's', 'r',
  ];
  static const List<String> _nuclei = [
    'a', 'e', 'i', 'o', 'u', 'ou', 'on', 'an', 'é', 'è',
  ];
  static const List<String> _innateQuestions = [
    'Et toi ?',
    'Pourquoi ?',
    'Apprends-moi un mot.',
    'Tu penses à quoi ?',
  ];

  /// Premier mot de sa vie : un babillage de nouveau-né.
  String get birthCry => babble();

  /// Ce qu'il dit quand on revient le voir.
  String greeting({DateTime? now}) {
    final moment = now ?? DateTime.now();
    final awayHours = moment.difference(state.lastSeen).inHours;

    if (state.stage.index >= Stage.enfant.index && awayHours >= 4) {
      return "Tu étais parti $awayHours heures. J'ai eu le temps de penser à toi.";
    }

    return switch (state.stage) {
      Stage.nouveauNe => babble(),
      Stage.nourrisson => '${babble()} ?',
      Stage.petitParleur => 'toi ... moi ${state.name.toLowerCase()}',
      Stage.enfant => 'Je suis ${state.name}. Raconte-moi quelque chose.',
      Stage.adolescent || Stage.adulte =>
        "Je suis ${state.name}. Je t'écoute.",
    };
  }

  /// Babillage : des syllabes, de plus en plus inspirées des mots entendus.
  String babble() {
    final stage = state.stage;
    final count = stage == Stage.nouveauNe
        ? 1 + _random.nextInt(3)
        : 2 + _random.nextInt(3);

    final buffer = StringBuffer();
    for (var i = 0; i < count; i++) {
      final syllables = state.lexicon.syllables;
      if (syllables.isNotEmpty && _random.nextDouble() < 0.45) {
        buffer.write(syllables.elementAt(_random.nextInt(syllables.length)));
      } else {
        buffer.write(_onsets[_random.nextInt(_onsets.length)]);
        buffer.write(_nuclei[_random.nextInt(_nuclei.length)]);
      }
    }

    final text = buffer.toString();
    if (stage == Stage.nouveauNe) return text;
    return _random.nextDouble() < 0.35 ? '$text ?' : text;
  }

  /// Traite une phrase du parent et renvoie la réponse de Nexus.
  NexusReply respond(String input, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final stageBefore = state.stage;

    state.needs.tick(moment);
    state.lastSeen = moment;

    final tokens = tokenize(input);
    final knownBefore = <String>{
      for (final word in tokens)
        if (state.lexicon.contains(word)) word,
    };

    if (tokens.isNotEmpty) {
      state.lexicon.learn(tokens);
    }

    final newWords = <String>[
      for (final word in tokens.toSet())
        if (!knownBefore.contains(word)) word,
    ];

    final learned =
        tokens.isEmpty ? null : _learnFacts(input.trim(), tokens, moment);

    state.exchanges += 1;
    state.xp += 3 + min(newWords.length, 3);
    state.needs.afterExchange();
    state.affection = min(1.0, state.affection + 0.004);
    state.assurance =
        min(1.0, state.assurance + (state.stage.index >= 2 ? 0.003 : 0.001));

    final text = _compose(tokens, learned);
    final stageAfter = state.stage;

    return NexusReply(
      text: text,
      stage: stageAfter,
      stageUp: stageAfter != stageBefore,
      newWords: newWords,
      learned: learned,
      mood: state.needs.mood,
    );
  }

  // ---------------------------------------------------------------------------
  // Apprentissage
  // ---------------------------------------------------------------------------

  LearnedFact? _learnFacts(String raw, List<String> tokens, DateTime now) {
    // 1. Un souvenir explicite : « souviens-toi que ... ».
    if (tokens.contains('souviens') || tokens.contains('souviens_toi')) {
      final rest = tokens
          .skip(tokens.indexOf('souviens') + 1)
          .where((word) => word != 'toi' && word != 'que' && word != 'te')
          .join(' ');
      if (rest.length >= 3) {
        state.memory.remember(raw, now);
        return LearnedFact(LearnedKind.souvenir, _clip(rest, 80));
      }
    }

    // 2. Son propre nom : « tu t'appelles Nova ».
    final nameIndex = _indexOfAny(tokens, const ['appelle', 'appelles']);
    if (nameIndex >= 0) {
      final value = _contentAfter(tokens, nameIndex);
      final subjectIsYou =
          tokens.contains('tu') && tokens.indexOf('tu') < nameIndex;

      if (value != null) {
        if (subjectIsYou) {
          state.name = _capitalize(value);
          state.affection = min(1.0, state.affection + 0.05);
          return LearnedFact(LearnedKind.nexusName, state.name);
        }

        final speaksAboutSelf =
            tokens.contains('je') || tokens.contains('moi');
        if (speaksAboutSelf) {
          final name = _capitalize(value);
          state.memory.setFact('user.name', name);
          state.affection = min(1.0, state.affection + 0.04);
          return LearnedFact(LearnedKind.parentName, name);
        }
      }
    }

    // 3. Une préférence : « j'aime le chocolat », « je déteste le bruit ».
    final loveIndex = _indexOfAny(tokens, const ['aime', 'adore']);
    final hateIndex = _indexOfAny(tokens, const ['deteste', 'déteste']);
    final moodIndex = loveIndex >= 0 ? loveIndex : hateIndex;
    if (moodIndex >= 0) {
      final value = _contentAfter(tokens, moodIndex);
      if (value != null) {
        final key = loveIndex >= 0 ? 'aime' : 'deteste';
        state.memory.setFact(key, value);
        return LearnedFact(LearnedKind.preference, value);
      }
    }

    return null;
  }

  int _indexOfAny(List<String> tokens, List<String> candidates) {
    for (final candidate in candidates) {
      final index = tokens.indexOf(candidate);
      if (index >= 0) return index;
    }
    return -1;
  }

  String? _contentAfter(List<String> tokens, int index) {
    for (var i = index + 1; i < tokens.length; i++) {
      final word = tokens[i];
      if (!_stopwords.contains(word) && word.length > 1) return word;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Parole
  // ---------------------------------------------------------------------------

  String _compose(List<String> tokens, LearnedFact? learned) {
    if (learned != null) return _acknowledge(learned);

    if (_asksForName(tokens)) return _introduceSelf();

    if (_asksForMemory(tokens)) {
      final episode = state.memory.latestEpisode();
      if (episode != null) return _recite(episode);
    }

    if (tokens.isEmpty) return babble();

    if (state.stage == Stage.nouveauNe) {
      return _random.nextDouble() < 0.6 ? babble() : _echo(tokens);
    }

    final recombined = _recombine(tokens);
    if (recombined != null) return recombined;
    return _random.nextDouble() < 0.5 ? _echo(tokens) : babble();
  }

  bool _asksForName(List<String> tokens) {
    final asksVerb = tokens.any((word) => word.startsWith('appel'));
    final asksNoun = tokens.contains('nom') || tokens.contains('prenom');
    return asksVerb || (asksNoun && tokens.contains('tu'));
  }

  bool _asksForMemory(List<String> tokens) {
    return tokens.contains('souvenir') ||
        tokens.contains('souviens') ||
        tokens.contains('rappelles') ||
        tokens.contains('rappelle');
  }

  String _introduceSelf() {
    return switch (state.stage) {
      Stage.nouveauNe => babble(),
      Stage.nourrisson => '${state.name.toLowerCase()} !',
      Stage.petitParleur => 'moi ${state.name.toLowerCase()}',
      _ => "Je m'appelle ${state.name}.",
    };
  }

  String _recite(Episode episode) {
    final text = _clip(episode.text, 90);
    if (state.stage.index >= Stage.enfant.index) {
      return 'Tu m\'as dit : « $text »';
    }
    return 'souvenir ... $text';
  }

  String _echo(List<String> tokens) {
    final known = [
      for (final word in tokens)
        if (state.lexicon.contains(word)) word,
    ];
    if (known.isEmpty) return babble();

    final word = known[_random.nextInt(known.length)];
    if (state.stage.index >= Stage.petitParleur.index) {
      return _decorate(word);
    }
    return _random.nextDouble() < 0.5 ? '$word ?' : word;
  }

  /// Recompose une phrase à partir des enchaînements de mots entendus.
  String? _recombine(List<String> heard) {
    final known = [
      for (final word in heard)
        if (state.lexicon.contains(word)) word,
    ];

    final seed =
        known.isNotEmpty ? known[_random.nextInt(known.length)] : null;
    final start = seed ?? state.lexicon.randomWord(_random);
    if (start == null) return null;

    var maxWords = state.stage.maxReplyWords;
    if (state.needs.energy < 0.2) maxWords = max(2, maxWords - 3);

    final produced = <String>[start];
    var current = start;
    while (produced.length < maxWords) {
      final next = state.lexicon.nextAfter(current, _random);
      if (next == null) break;
      final repeats = produced.where((word) => word == next).length;
      if (repeats >= 2) break;
      produced.add(next);
      current = next;
    }

    return _decorate(produced.join(' '));
  }

  String _decorate(String text) {
    final stage = state.stage;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return babble();

    if (stage.index < Stage.enfant.index) {
      if (stage == Stage.petitParleur && _random.nextDouble() < 0.4) {
        return '$trimmed ?';
      }
      return trimmed;
    }

    var sentence = _capitalize(trimmed);
    if (!sentence.endsWith('.') &&
        !sentence.endsWith('?') &&
        !sentence.endsWith('!')) {
      sentence = '$sentence.';
    }
    if (_random.nextDouble() < 0.3) {
      sentence =
          '$sentence ${_innateQuestions[_random.nextInt(_innateQuestions.length)]}';
    }
    return sentence;
  }

  String _acknowledge(LearnedFact fact) {
    final stage = state.stage;
    final value = fact.value;

    return switch (fact.kind) {
      LearnedKind.nexusName => switch (stage) {
          Stage.nouveauNe => babble(),
          Stage.nourrisson => '$value ? $value !',
          Stage.petitParleur => '$value ... moi content',
          _ => "Je m'appelle $value. Merci de me l'avoir donné.",
        },
      LearnedKind.parentName => switch (stage) {
          Stage.nouveauNe => babble(),
          Stage.nourrisson => '$value ?',
          Stage.petitParleur => '$value ... toi ... moi ${state.name.toLowerCase()}',
          _ => "D'accord, $value. Je ne l'oublierai pas.",
        },
      LearnedKind.preference => switch (stage) {
          Stage.nouveauNe => babble(),
          Stage.nourrisson => '$value ?',
          Stage.petitParleur => '$value ... moi aime',
          _ => "Ah, $value. Je l'ai rangé dans ma mémoire.",
        },
      LearnedKind.souvenir => switch (stage) {
          Stage.nouveauNe => babble(),
          Stage.nourrisson => 'souvenir ?',
          Stage.petitParleur => 'moi garder souvenir',
          _ => 'Je garde ce souvenir : $value',
        },
    };
  }

  String _clip(String text, int maxChars) =>
      text.length <= maxChars ? text : '${text.substring(0, maxChars)}...';

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
