import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stups/app.dart';
import 'package:stups/core/app_info/app_info_provider.dart';
import 'package:stups/core/router/app_router.dart';
import 'package:stups/core/theme/app_theme.dart';
import 'package:stups/features/shell/placeholder_page.dart';

import '../../support/marker_localizations.dart';

/// Seam 1: Alle Oberflächentexte kommen aus den Sprachdateien. Die
/// Test-Übersetzung ersetzt jeden Text durch einen Marker; was keinen Marker
/// zeigt, steht fest im Code.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String? location,
    String version = '0.0.0-test',
  }) async {
    final router = createRouter(initialLocation: location ?? AppRoutes.today);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Stups',
              packageName: 'de.dorios.stups',
              version: version,
              buildNumber: '1',
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: StupsTheme.light,
          localizationsDelegates: markerLocalizationsDelegates,
          supportedLocales: const [Locale('de')],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Seiten der Tabs', () {
    const pages = <({String location, String titleKey, String hintKey})>[
      (location: AppRoutes.today, titleKey: 'tabToday', hintKey: 'todayHint'),
      (location: AppRoutes.tasks, titleKey: 'tabTasks', hintKey: 'tasksHint'),
      (
        location: AppRoutes.routines,
        titleKey: 'tabRoutines',
        hintKey: 'routinesHint',
      ),
      (
        location: AppRoutes.household,
        titleKey: 'tabHousehold',
        hintKey: 'householdHint',
      ),
      (location: AppRoutes.more, titleKey: 'tabMore', hintKey: 'moreHint'),
    ];

    for (final page in pages) {
      testWidgets(
        '${page.location} zeigt Titel und Hinweis aus den Sprachdateien',
        (tester) async {
          await pumpApp(tester, location: page.location);

          final pageFinder = find.byType(PlaceholderPage);
          expect(
            find.descendant(
              of: pageFinder,
              matching: find.text(marker(page.titleKey)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: pageFinder,
              matching: find.text(marker(page.hintKey)),
            ),
            findsOneWidget,
          );
        },
      );
    }
  });

  testWidgets('der Plus-Button trägt seinen Hinweis aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byTooltip(marker('captureTooltip')), findsOneWidget);
  });

  testWidgets('„Mehr“ zeigt die Version mit dem Text aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.more, version: '0.1.0-dev');

    expect(find.text(marker('moreVersion', '0.1.0-dev')), findsOneWidget);
  });

  testWidgets('der App-Titel kommt aus den Sprachdateien', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StupsApp(localizationsDelegates: markerLocalizationsDelegates),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final context = tester.element(find.byType(Scaffold).first);
    expect(app.onGenerateTitle?.call(context), marker('appTitle'));
  });

  testWidgets('die fünf Tabs tragen die Texte aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final key in [
      'tabToday',
      'tabTasks',
      'tabRoutines',
      'tabHousehold',
      'tabMore',
    ]) {
      expect(
        find.widgetWithText(NavigationDestination, marker(key)),
        findsOneWidget,
        reason: 'Tab "$key" zeigt seinen Marker nicht',
      );
    }
  });
}
