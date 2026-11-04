import 'package:nexus_core/nexus_core.dart';
import 'package:test/test.dart';

NexusBrain freshBrain({int seed = 42}) => NexusBrain(
      state: NexusState(name: 'Nexus', bornAt: DateTime.utc(2026, 1, 1)),
      seed: seed,
    );

void main() {
  test('Nexus naît sans un seul mot', () {
    final brain = freshBrain();
    expect(brain.state.lexicon.size, 0);
    expect(brain.state.xp, 0);
    expect(brain.state.exchanges, 0);
    expect(brain.state.memory.episodes, isEmpty);
    expect(brain.state.stage, Stage.nouveauNe);
  });

  test('il babille et apprend en même temps', () {
    final brain = freshBrain();
    final reply = brain.respond('bonjour je suis content');

    expect(reply.text.trim(), isNotEmpty);
    expect(reply.stage, Stage.nouveauNe);
    expect(brain.state.lexicon.contains('bonjour'), isTrue);
    expect(brain.state.lexicon.contains('content'), isTrue);
    expect(brain.state.exchanges, 1);
    expect(brain.state.xp, greaterThan(0));
    expect(reply.newWords, contains('bonjour'));
  });

  test('il retient le prénom de son parent', () {
    final brain = freshBrain();
    final reply = brain.respond("je m'appelle Léo");

    expect(brain.state.memory.fact('user.name'), 'Léo');
    expect(reply.learned?.kind, LearnedKind.parentName);
  });

  test('on peut lui donner un nouveau nom', () {
    final brain = freshBrain();
    brain.respond("tu t'appelles Nova");

    expect(brain.state.name, 'Nova');
    expect(brain.state.stage, Stage.nouveauNe);
  });

  test('il garde un souvenir et sait le redire', () {
    final brain = freshBrain();
    brain.respond("souviens-toi que j'aime la pluie du soir");

    expect(brain.state.memory.episodes, isNotEmpty);
    expect(brain.state.memory.latestEpisode()!.text, contains('pluie'));

    // Il grandit d'abord, puis on lui demande de se rappeler.
    brain.state.xp = 200;
    final recall = brain.respond('tu te souviens ?');
    expect(recall.text, contains('pluie'));
  });

  test('il retient une préférence', () {
    final brain = freshBrain();
    brain.respond("j'aime le chocolat");

    expect(brain.state.memory.fact('aime'), 'chocolat');
  });

  test('il répond à la question de son nom quand il grandit', () {
    final brain = freshBrain();
    brain.state.xp = 90; // petit parleur
    final reply = brain.respond('comment tu t appelles ?');

    expect(reply.text.toLowerCase(), contains('nexus'));
  });

  test('il grandit à force de parler', () {
    final brain = freshBrain();
    for (var i = 0; i < 60; i++) {
      brain.respond('je regarde le ciel et les étoiles brillent ce soir');
    }

    expect(brain.state.stage.index, greaterThan(Stage.nouveauNe.index));
    expect(brain.state.lexicon.size, greaterThan(8));
    expect(brain.state.exchanges, 60);
  });

  test('un stade franchi est signalé', () {
    final brain = freshBrain();
    var sawStageUp = false;
    for (var i = 0; i < 40; i++) {
      final reply = brain.respond('je regarde le ciel et les étoiles');
      if (reply.stageUp) sawStageUp = true;
    }

    expect(sawStageUp, isTrue);
  });

  test('deux cerveaux avec la même graine disent la même chose', () {
    final a = freshBrain(seed: 7).respond('bonjour le monde').text;
    final b = freshBrain(seed: 7).respond('bonjour le monde').text;

    expect(a, b);
  });

  test('ses besoins dérivent quand on l abandonne', () {
    final brain = freshBrain();
    final before = brain.state.needs.attention;
    brain.state.needs.tick(
      brain.state.needs.lastTick.add(const Duration(hours: 2)),
    );

    expect(brain.state.needs.attention, lessThan(before));
  });

  test('son état survit à un aller-retour JSON', () {
    final brain = freshBrain();
    brain.respond('je m appelle Léo et j aime le ciel');

    final decoded = NexusState.decode(brain.state.encode());

    expect(decoded.name, brain.state.name);
    expect(decoded.xp, brain.state.xp);
    expect(decoded.exchanges, brain.state.exchanges);
    expect(decoded.lexicon.size, brain.state.lexicon.size);
    expect(decoded.memory.fact('user.name'), 'Léo');
    expect(decoded.stage, brain.state.stage);
  });

  test('ses réponses restent courtes quand il est nouveau-né', () {
    final brain = freshBrain();
    for (var i = 0; i < 10; i++) {
      final reply = brain.respond('le soleil brille sur la mer immense');
      expect(reply.text.split(RegExp(r'\s+')).length, lessThan(6));
    }
  });
}
