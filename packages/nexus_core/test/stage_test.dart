import 'package:nexus_core/nexus_core.dart';
import 'package:test/test.dart';

void main() {
  test('un Nexus qui vient de naître est un nouveau-né', () {
    expect(stageForXp(0), Stage.nouveauNe);
    expect(stageForXp(24), Stage.nouveauNe);
  });

  test("l'expérience fait grandir", () {
    expect(stageForXp(25), Stage.nourrisson);
    expect(stageForXp(80), Stage.petitParleur);
    expect(stageForXp(200), Stage.enfant);
    expect(stageForXp(450), Stage.adolescent);
    expect(stageForXp(900), Stage.adulte);
  });

  test('chaque stade a un successeur, sauf le dernier', () {
    expect(Stage.nouveauNe.nextStage, Stage.nourrisson);
    expect(Stage.adulte.nextStage, isNull);
  });

  test('les réponses autorisées grandissent avec les stades', () {
    expect(Stage.nouveauNe.maxReplyWords, lessThan(Stage.adulte.maxReplyWords));
  });
}
