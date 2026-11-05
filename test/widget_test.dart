import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/ui/brain_toggle_view.dart';

void main() {
  testWidgets('app launches with toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: BrainApp(),
      debugShowCheckedModeBanner: false,
    ));
    await tester.pump();
    expect(find.byType(BrainApp), findsOneWidget);
  });
}
