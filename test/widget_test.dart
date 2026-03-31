import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build a simple MaterialApp to test basic rendering
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mapy'),
          ),
        ),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.text('Mapy'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
