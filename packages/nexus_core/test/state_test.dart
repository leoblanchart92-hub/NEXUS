import 'package:nexus_core/nexus_core.dart';
import 'package:test/test.dart';

void main() {
  test('un Nexus neuf ne sait rien', () {
    final state = NexusState(name: 'Nexus');

    expect(state.memory.isEmpty, isTrue);
    expect(state.memory.size, 0);
    expect(state.persona, isEmpty);
    expect(state.voiceEnabled, isFalse);
  });

  test('son état survit à un aller-retour JSON', () {
    final state = NexusState(
      name: 'Nova',
      bornAt: DateTime.utc(2026, 1, 1),
      voiceEnabled: true,
      persona: 'Tu es directe.',
    );
    state.memory
      ..setFact('prenom', 'Léo')
      ..remember('Il aime la pluie', DateTime.utc(2026, 1, 2))
      ..learnLesson('orbe', 'Une sphère lumineuse', DateTime.utc(2026, 1, 2));

    final decoded = NexusState.decode(state.encode());

    expect(decoded.name, 'Nova');
    expect(decoded.voiceEnabled, isTrue);
    expect(decoded.persona, 'Tu es directe.');
    expect(decoded.memory.fact('prenom'), 'Léo');
    expect(decoded.memory.episodes.single.text, 'Il aime la pluie');
    expect(decoded.memory.lessonFor('orbe')!.definition,
        'Une sphère lumineuse');
  });

  test('un ancien état sans mémoire reste lisible', () {
    final decoded = NexusState.decode('{"name": "Nexus"}');

    expect(decoded.name, 'Nexus');
    expect(decoded.memory.isEmpty, isTrue);
    expect(decoded.persona, isEmpty);
  });
}
