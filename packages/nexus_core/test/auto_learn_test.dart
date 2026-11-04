import 'package:nexus_core/nexus_core.dart';
import 'package:test/test.dart';

void main() {
  test('lit un JSON propre avec faits, souvenirs et leçons', () {
    final update = MemoryUpdate.fromModelOutput(
      '{"faits": {"prénom": "Léo", "ville": "Lyon"}, '
      '"souvenirs": ["Il déteste les lundis matin"], '
      '"lecons": {"orbe": "Une sphère lumineuse"}}',
    );

    expect(update, isNotNull);
    expect(update!.facts['prénom'], 'Léo');
    expect(update.facts['ville'], 'Lyon');
    expect(update.episodes, contains('Il déteste les lundis matin'));
    expect(update.lessons['orbe'], 'Une sphère lumineuse');
  });

  test('lit un JSON entouré de texte et de balises Markdown', () {
    final update = MemoryUpdate.fromModelOutput(
      'Voici ce que je retiens :\n```json\n'
      '{"facts": {"dog": "un chat nommé Pixel"}, "episodes": ["Il a déménagé"]}\n'
      '```\nVoilà.',
    );

    expect(update, isNotNull);
    expect(update!.facts['dog'], 'un chat nommé Pixel');
    expect(update.episodes, contains('Il a déménagé'));
  });

  test('accepte des faits donnés sous forme de liste', () {
    final update = MemoryUpdate.fromModelOutput(
      '{"faits": ["métier: développeur", "humeur: fatigué"]}',
    );

    expect(update, isNotNull);
    expect(update!.facts['métier'], 'développeur');
    expect(update.facts['humeur'], 'fatigué');
  });

  test('renvoie null quand il n y a rien à retenir', () {
    expect(MemoryUpdate.fromModelOutput('{}'), isNull);
    expect(MemoryUpdate.fromModelOutput('Je ne retiens rien.'), isNull);
    expect(MemoryUpdate.fromModelOutput('{"faits": {}}'), isNull);
    expect(MemoryUpdate.fromModelOutput(''), isNull);
  });

  test('ignore les valeurs vides, nulles ou trop courtes', () {
    final update = MemoryUpdate.fromModelOutput(
      '{"faits": {"ville": "", "age": null, "x": "a", "nom": "Léo"}}',
    );

    expect(update, isNotNull);
    expect(update!.facts.keys, ['nom']);
    expect(update.facts['nom'], 'Léo');
  });

  test('nettoie les clés pour éviter les doublons', () {
    final update = MemoryUpdate.fromModelOutput(
      '{"faits": {"Prénom humain": "Léo", "méteir": "dev"}}',
    );

    expect(update, isNotNull);
    expect(update!.facts.containsKey('prénom_humain'), isTrue);
  });

  test('écrit tout dans la mémoire et fusionne les faits', () {
    final memory = Memory()..setFact('ville', 'Paris');
    final update = MemoryUpdate.fromModelOutput(
      '{"faits": {"ville": "Lyon"}, "souvenirs": ["Son chat sappelle Pixel"]}',
    )!;

    update.applyTo(memory);

    expect(memory.fact('ville'), 'Lyon');
    expect(memory.episodes.single.text, contains('Pixel'));
  });

  test('ne stocke pas deux fois le même souvenir', () {
    final memory = Memory();
    final at = DateTime.utc(2026, 3, 1);

    memory.remember('Son chat sappelle Pixel', at);
    memory.remember(
      'Son chat sappelle Pixel',
      at.add(const Duration(hours: 1)),
    );

    expect(memory.episodes.length, 1);
  });

  test('sa mémoire reste bornée', () {
    final memory = Memory();
    final update = MemoryUpdate.fromModelOutput(
      '{"souvenirs": ${List<String>.generate(3, (int i) => '"souvenir $i"')}}',
    )!;

    update.applyTo(memory);
    expect(memory.episodes.length, 3);

    for (var i = 0; i < Memory.maxEpisodes + 20; i++) {
      memory.remember('souvenir numéro $i', DateTime.utc(2026, 1, 1));
    }
    expect(memory.episodes.length, Memory.maxEpisodes);
  });

  test('forgetAll efface tout ce qu elle a appris', () {
    final memory = Memory()
      ..setFact('prenom', 'Léo')
      ..remember('Un souvenir', DateTime.utc(2026, 1, 1))
      ..learnLesson('orbe', 'Une sphère', DateTime.utc(2026, 1, 1));

    expect(memory.size, 3);
    memory.forgetAll();
    expect(memory.isEmpty, isTrue);
  });
}
