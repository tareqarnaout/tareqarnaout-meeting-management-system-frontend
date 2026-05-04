import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/minute_taker_screen.dart';

void main() {
  testWidgets('Minute Taker screen renders core sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MinuteTakerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Live Transcript'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Handoff to Secretary'), findsOneWidget);
  });
}
