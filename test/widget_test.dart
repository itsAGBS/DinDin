import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Teste basico de renderizacao', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('DinDin'),
        ),
      ),
    );

    expect(find.text('DinDin'), findsOneWidget);
  });
}