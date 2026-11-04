import 'package:nexus_core/nexus_core.dart';
import 'package:test/test.dart';

NexusBrain freshBrain({int seed = 42}) => NexusBrain(
      state: NexusState(name: 'Nexus', bornAt: DateTime.utc(2026, 1, 1)),
      seed: seed,
    );

void main() {
  test('il apprend une leçon et la range dans sa mémoire', () {
    final brain = freshBrain();
    final result = brain.teach('lune', 'le satellite de la Terre');

    expect(result.xpGained, NexusBrain.xpPerLesson);
    expect(brain.state.memory.lessonFor('lune'), isNotNull);
    expect(brain.state.memory.lessonFor('LUNE')!.definition,
        'le satellite de la Terre');
    expect(brain.state.xp, NexusBrain.xpPerLesson);
  });

  test('une leçon le fait grandir dix fois plus vite qu une phrase', () {
    final brain = freshBrain();
    final before = brain.state.xp;
    brain.teach('mer', 'la grande étendue d eau salée');
    brain.teach('ciel', 'l espace au dessus de nos têtes');
    brain.teach('arbre', 'une plante avec un tronc');

    expect(brain.state.xp - before, 3 * NexusBrain.xpPerLesson);
    expect(brain.state.stage, Stage.nourrisson);
  });

  test('il récite une leçon quand on la lui demande', () {
    final brain = freshBrain();
    brain.state.xp = 200; // enfant
    brain.teach('lune', 'le satellite de la Terre');

    final reply = brain.respond("c'est quoi la lune ?");
    expect(reply.text.toLowerCase(), contains('satellite'));
  });

  test('il ne récite pas une leçon qu il n a pas apprise', () {
    final brain = freshBrain();
    brain.state.xp = 200;

    final reply = brain.respond("c'est quoi la lune ?");
    expect(reply.text.toLowerCase(), isNot(contains('satellite')));
  });

  test('« récite-moi » renvoie une de ses leçons', () {
    final brain = freshBrain();
    brain.state.xp = 200;
    brain.teach('lune', 'le satellite de la Terre');

    final reply = brain.respond('récite-moi une leçon');
    expect(reply.text.toLowerCase(), contains('satellite'));
  });

  test('les leçons survivent à un aller-retour JSON', () {
    final brain = freshBrain();
    brain.teach('lune', 'le satellite de la Terre');

    final decoded = NexusState.decode(brain.state.encode());
    expect(decoded.memory.lessonFor('lune')!.definition,
        'le satellite de la Terre');
  });

  test('la voix est éteinte par défaut et se retient', () {
    final brain = freshBrain();
    expect(brain.state.voiceEnabled, isFalse);

    brain.state.voiceEnabled = true;
    final decoded = NexusState.decode(brain.state.encode());
    expect(decoded.voiceEnabled, isTrue);
  });
}
