import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/app.dart';
import 'package:stups/core/theme/app_theme.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StupsApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('startet auf „Heute“ mit fünf Tabs und dem Plus-Button', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Hier steht bald dein nächster Schritt.'), findsOneWidget);
    for (final label in ['Heute', 'Aufgaben', 'Routinen', 'Haushalt', 'Mehr']) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
    expect(find.byTooltip('Kopf frei machen'), findsOneWidget);
  });

  testWidgets('wechselt zwischen den Tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Aufgaben'));
    await tester.pumpAndSettle();
    expect(
      find.text('Hier landen bald deine Aufgaben und die Inbox.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Haushalt'));
    await tester.pumpAndSettle();
    expect(find.text('Der Haushalt kommt in Version 0.3.'), findsOneWidget);
  });

  test('Hell- und Dunkel-Theme verwenden die Stups-Schriften', () {
    for (final theme in [StupsTheme.light, StupsTheme.dark]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Lexend');
      expect(theme.textTheme.headlineMedium?.fontFamily, 'Fredoka');
    }
  });
}
