import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort/ui/widgets/game_button.dart';

void main() {
  testWidgets('GameButton renders and responds to tap', (
    WidgetTester tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameButton(
            label: 'Play',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();

    expect(pressed, isTrue);
  });
}
