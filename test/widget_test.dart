import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/app_update.dart';
import 'package:nexus/main.dart';
import 'package:nexus/ui/ai_home_view.dart';

void main() {
  testWidgets("l'écran liste les IA à télécharger", (WidgetTester tester) async {
    await tester.pumpWidget(const NexusApp());
    await tester.pump();

    expect(find.byType(AiHomeView), findsOneWidget);
    expect(find.text('Nexus'), findsOneWidget);
    expect(find.text('Qwen3 0.6B'), findsOneWidget);
    expect(find.text('Qwen3 1.7B'), findsOneWidget);

    // Le pied de page, avec la version et le bouton de mise à jour, se trouve
    // sous la liste : il faut y descendre pour qu'il soit construit.
    await tester.dragUntilVisible(
      find.text('Vérifier les mises à jour'),
      find.byType(ListView),
      const Offset(0, -240),
    );
    expect(find.text('Vérifier les mises à jour'), findsOneWidget);
    expect(find.text('Nexus $nexusVersion'), findsOneWidget);
  });
}
