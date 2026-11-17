import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/l10n/area_display_name.dart';
import 'package:stups/l10n/app_localizations_de.dart';
import 'package:stups/l10n/app_localizations_en.dart';

import '../../support/marker_localizations.dart';

/// Seam 2: Der Anzeigename eines Bereichs. Eingebaute Bereiche tragen keinen
/// Text in der Datenbank; ihr Name kommt aus den Sprachdateien.
void main() {
  Area area({String? builtInKey, String? name}) => Area(
    id: 'id',
    builtInKey: builtInKey,
    name: name,
    colorKey: 'coral',
    iconKey: 'home',
    hidden: false,
  );

  final markers = MarkerLocalizations();

  group('eingebaute Bereiche', () {
    test('zeigen den Text zu ihrer Kennung aus den Sprachdateien', () {
      expect(
        areaDisplayName(markers, area(builtInKey: BuiltInArea.household)),
        marker('areaHousehold'),
      );
      expect(
        areaDisplayName(markers, area(builtInKey: BuiltInArea.work)),
        marker('areaWork'),
      );
      expect(
        areaDisplayName(markers, area(builtInKey: BuiltInArea.personal)),
        marker('areaPersonal'),
      );
    });

    test('heißen auf Deutsch Haushalt, Arbeit und Persönliches', () {
      final de = AppLocalizationsDe();

      expect(
        areaDisplayName(de, area(builtInKey: BuiltInArea.household)),
        'Haushalt',
      );
      expect(areaDisplayName(de, area(builtInKey: BuiltInArea.work)), 'Arbeit');
      expect(
        areaDisplayName(de, area(builtInKey: BuiltInArea.personal)),
        'Persönliches',
      );
    });

    test('heißen auf Englisch Home, Work und Personal', () {
      final en = AppLocalizationsEn();

      expect(
        areaDisplayName(en, area(builtInKey: BuiltInArea.household)),
        'Home',
      );
      expect(areaDisplayName(en, area(builtInKey: BuiltInArea.work)), 'Work');
      expect(
        areaDisplayName(en, area(builtInKey: BuiltInArea.personal)),
        'Personal',
      );
    });

    test('eine unbekannte Kennung zeigt die Kennung selbst', () {
      expect(
        areaDisplayName(markers, area(builtInKey: 'gibt-es-nicht')),
        'gibt-es-nicht',
      );
    });
  });

  group('eigene Bereiche', () {
    test('zeigen ihren eigenen Namen', () {
      expect(areaDisplayName(markers, area(name: 'Garten')), 'Garten');
    });

    test('ein eigener Name gewinnt gegenüber der Kennung', () {
      expect(
        areaDisplayName(
          markers,
          area(builtInKey: BuiltInArea.household, name: 'Zuhause'),
        ),
        'Zuhause',
      );
    });
  });
}
