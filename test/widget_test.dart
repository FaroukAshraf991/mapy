
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapy/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MapyApp(homeScreen: const Placeholder()));

    // Verify that the app loads without crashing.
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
