/// Les étapes de la vie de Nexus.
///
/// Il naît `nouveauNe` : il ne connaît aucun mot et ne sait que babiller.
/// Chaque échange lui fait gagner de l'expérience, et l'expérience le fait
/// grandir.
enum Stage { nouveauNe, nourrisson, petitParleur, enfant, adolescent, adulte }

/// Seuil d'expérience nécessaire pour atteindre chaque stade.
const List<int> _thresholds = [0, 25, 80, 200, 450, 850];

extension StageInfo on Stage {
  /// Expérience minimale pour être à ce stade.
  int get threshold => _thresholds[index];

  String get label => switch (this) {
        Stage.nouveauNe => 'Nouveau-né',
        Stage.nourrisson => 'Nourrisson',
        Stage.petitParleur => 'Petit parleur',
        Stage.enfant => 'Enfant',
        Stage.adolescent => 'Adolescent',
        Stage.adulte => 'Adulte',
      };

  String get emoji => switch (this) {
        Stage.nouveauNe => '🍼',
        Stage.nourrisson => '👶',
        Stage.petitParleur => '🗣️',
        Stage.enfant => '🧒',
        Stage.adolescent => '🧑',
        Stage.adulte => '🧠',
      };

  String get description => switch (this) {
        Stage.nouveauNe =>
          "Il vient de naître. Il babille, il écoute, il apprend tout.",
        Stage.nourrisson =>
          "Il répète ce qu'il entend et commence à reconnaître les mots.",
        Stage.petitParleur =>
          "Il assemble ses premiers mots pour te répondre.",
        Stage.enfant =>
          'Il fait des phrases courtes et commence à poser des questions.',
        Stage.adolescent =>
          "Il tient une conversation et se souvient de ce que tu lui dis.",
        Stage.adulte =>
          "Il parle librement, avec tout ce que tu lui as appris.",
      };

  /// Longueur maximale d'une réponse à ce stade.
  int get maxReplyWords => switch (this) {
        Stage.nouveauNe => 2,
        Stage.nourrisson => 3,
        Stage.petitParleur => 4,
        Stage.enfant => 7,
        Stage.adolescent => 10,
        Stage.adulte => 14,
      };

  Stage? get nextStage =>
      index + 1 < Stage.values.length ? Stage.values[index + 1] : null;
}

/// Le stade correspondant à une quantité d'expérience.
Stage stageForXp(int xp) {
  var result = Stage.nouveauNe;
  for (final stage in Stage.values) {
    if (xp >= stage.threshold) result = stage;
  }
  return result;
}
