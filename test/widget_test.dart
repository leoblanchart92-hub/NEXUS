import 'package:flutter_test/flutter_test.dart';

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
  });
}
