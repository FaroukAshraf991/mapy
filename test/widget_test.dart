
import 'package:flutter_test/flutter_test.dart';

import 'package:mapy/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MapyApp());

    // Verify that the login screen is presented.
    expect(find.text('Welcome to Mapy'), findsOneWidget);
  });
}
