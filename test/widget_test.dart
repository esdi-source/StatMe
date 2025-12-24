// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statme/src/core/config/app_config.dart';
import 'package:statme/src/services/in_memory_database.dart';
import 'package:statme/src/ui/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Initialize AppConfig in Demo Mode
    await AppConfig.initialize(forceDemoMode: true);
    await InMemoryDatabase().initialize();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: StatMeApp(),
      ),
    );

    // Verify that the app builds
    expect(find.byType(StatMeApp), findsOneWidget);
  });
}
