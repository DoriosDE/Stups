import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/settings/settings_repository.dart';

import '../../support/app_harness.dart';

/// Die Einstellungen für Begleiter, Vibrieren und Animationen.
void main() {
  testWidgets('über „Mehr“ erreichbar; Schalter und Name werden gespeichert', (
    tester,
  ) async {
    final db = await pumpStupsApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begleiter anzeigen'));
    await tester.tap(find.text('Vibrieren bei Erfolgen'));
    await tester.tap(find.text('Animationen reduzieren'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name des Begleiters'),
      '  Flocke ',
    );
    await tester.pumpAndSettle();

    final saved = (await tester.runAsync(
      () => SettingsRepository(db).watch().first,
    ))!;
    expect(saved.showCompanion, isFalse);
    expect(saved.haptics, isFalse);
    expect(saved.reduceAnimations, isTrue);
    expect(saved.companionName, 'Flocke');
  });

  testWidgets('das Namensfeld zeigt den gespeicherten Namen', (tester) async {
    await pumpStupsApp(
      tester,
      seed: (db) => SettingsRepository(db).setCompanionName('Flocke'),
    );
    await tester.tap(find.widgetWithText(NavigationDestination, 'Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Flocke'), findsOneWidget);
  });
}
