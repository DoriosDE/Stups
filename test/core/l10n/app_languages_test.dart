import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stups/app.dart';
import 'package:stups/core/app_info/app_info_provider.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';

/// Die App folgt der Systemsprache und zeigt echte Texte in
/// Deutsch oder Englisch; ohne unterstützte Sprache gilt Englisch. Die
/// erwarteten Texte stehen hier als Literale, unabhängig von den Sprachdateien.
/// Ob der Wortlaut gut ist, prüft das Review.
void main() {
  Future<void> pumpApp(WidgetTester tester, List<Locale> systemLocales) async {
    tester.platformDispatcher.localesTestValue = systemLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    // Die Datenbank erst schließen, wenn die Oberfläche ihre Streams abbestellt
    // hat (siehe docs/HANDOFF.md, „Datenbank“).
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Stups',
              packageName: 'de.dorios.stups',
              version: '0.1.0',
              buildNumber: '1000',
            ),
          ),
        ],
        child: const StupsApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  const tabsDe = ['Heute', 'Aufgaben', 'Routinen', 'Haushalt', 'Mehr'];
  const tabsEn = ['Today', 'Tasks', 'Routines', 'Household', 'More'];

  void expectTabs(List<String> labels) {
    for (final label in labels) {
      expect(
        find.widgetWithText(NavigationDestination, label),
        findsOneWidget,
        reason: 'Tab "$label" fehlt',
      );
    }
  }

  group('die App folgt der Systemsprache', () {
    testWidgets('Englisch zeigt englische Texte', (tester) async {
      await pumpApp(tester, const [Locale('en', 'US')]);

      expectTabs(tabsEn);
      expect(find.text('All quiet. Want to clear your head?'), findsOneWidget);
      expect(find.byTooltip('Clear your head'), findsOneWidget);
    });

    testWidgets('Deutsch zeigt deutsche Texte', (tester) async {
      await pumpApp(tester, const [Locale('de', 'DE')]);

      expectTabs(tabsDe);
      expect(
        find.text('Alles ruhig. Magst du Kopf frei machen?'),
        findsOneWidget,
      );
      expect(find.byTooltip('Kopf frei machen'), findsOneWidget);
    });

    testWidgets('Österreichisches Deutsch zeigt deutsche Texte', (
      tester,
    ) async {
      await pumpApp(tester, const [Locale('de', 'AT')]);

      expectTabs(tabsDe);
    });

    testWidgets('die Versionsanzeige folgt der Sprache', (tester) async {
      await pumpApp(tester, const [Locale('en')]);
      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await tester.pumpAndSettle();

      expect(find.text('Version 0.1.0'), findsOneWidget);
    });
  });

  group('Rückfall', () {
    testWidgets('eine nicht unterstützte Sprache ergibt Englisch', (
      tester,
    ) async {
      await pumpApp(tester, const [Locale('fr', 'FR')]);

      expectTabs(tabsEn);
    });

    testWidgets('ohne Systemsprache ergibt Englisch', (tester) async {
      await pumpApp(tester, const []);

      expectTabs(tabsEn);
    });

    testWidgets('die erste unterstützte Systemsprache gewinnt', (tester) async {
      await pumpApp(tester, const [Locale('fr'), Locale('de'), Locale('en')]);

      expectTabs(tabsDe);
    });
  });
}
