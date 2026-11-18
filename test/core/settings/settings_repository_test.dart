import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/settings/settings_repository.dart';

/// Die Einstellungen, die „Heute“ und die Feier brauchen.
void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  Future<AppSettings> current() => settings.watch().first;

  test('ohne gespeicherte Werte gelten die Voreinstellungen', () async {
    final value = await current();

    expect(value.companionName, isNull);
    expect(value.showCompanion, isTrue);
    expect(value.haptics, isTrue);
    expect(value.reduceAnimations, isFalse);
  });

  test('geänderte Werte bleiben gespeichert, jeder für sich', () async {
    await settings.setCompanionName('Flocke');
    await settings.setShowCompanion(false);
    await settings.setHaptics(false);
    await settings.setReduceAnimations(true);

    final value = await current();
    expect(value.companionName, 'Flocke');
    expect(value.showCompanion, isFalse);
    expect(value.haptics, isFalse);
    expect(value.reduceAnimations, isTrue);

    await settings.setHaptics(true);
    final again = await current();
    expect(again.haptics, isTrue);
    expect(again.companionName, 'Flocke');
  });

  test('der Name wird gekürzt; leer heißt wieder Standardname', () async {
    await settings.setCompanionName('  Flocke  ');
    expect((await current()).companionName, 'Flocke');

    await settings.setCompanionName('   ');
    expect((await current()).companionName, isNull);

    await settings.setCompanionName('Flocke');
    await settings.setCompanionName(null);
    expect((await current()).companionName, isNull);
  });

  test('watch meldet den Anfangswert und jede Änderung', () async {
    final seen = expectLater(
      settings.watch().map((value) => value.haptics),
      emitsInOrder([true, false]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await settings.setHaptics(false);

    await seen;
  });
}
