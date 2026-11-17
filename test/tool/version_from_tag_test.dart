import 'package:flutter_test/flutter_test.dart';

import '../../tool/version_from_tag.dart';

void main() {
  group('Release-Tag', () {
    test('v0.1.0 ergibt Name 0.1.0, Code 1000 und Flavor prod', () {
      final version = versionFromTag('v0.1.0');

      expect(version.name, '0.1.0');
      expect(version.code, 1000);
      expect(version.flavor, BuildFlavor.prod);
    });

    test('rechnet Minor und Patch in die richtigen Stellen', () {
      expect(versionFromTag('v0.2.3').code, 2003);
      expect(versionFromTag('v1.0.0').code, 1000000);
      expect(versionFromTag('v12.34.567').code, 12034567);
    });
  });

  group('ungültige Tags', () {
    const invalid = <String, String>{
      'ohne v': '0.1.0',
      'nur zwei Zahlen': 'v0.1',
      'vier Zahlen': 'v0.1.0.1',
      'anderer Zusatz': 'v0.1.0-beta',
      'Zusatz großgeschrieben': 'v0.1.0-DEV',
      'führende Null bei Major': 'v01.2.3',
      'führende Null bei Minor': 'v1.02.3',
      'führende Null bei Patch': 'v1.2.03',
      'Leerzeichen am Ende': 'v0.1.0 ',
      'Zeilenumbruch am Ende': 'v0.1.0\n',
      'leerer Text': '',
      'nur v': 'v',
    };

    invalid.forEach((reason, tag) {
      test('$reason ($tag) bricht ab', () {
        expect(() => versionFromTag(tag), throwsA(isA<InvalidTagException>()));
      });
    });

    test('die Fehlermeldung nennt den Tag und das erwartete Format', () {
      expect(
        () => versionFromTag('v0.1'),
        throwsA(
          isA<InvalidTagException>().having(
            (e) => e.toString(),
            'Meldung',
            allOf(contains('v0.1'), contains('v<Major>.<Minor>.<Patch>')),
          ),
        ),
      );
    });
  });

  group('Grenzen', () {
    test('Minor und Patch bis 999 sind erlaubt', () {
      expect(versionFromTag('v0.999.999').code, 999999);
      expect(versionFromTag('v1.999.999').code, 1999999);
    });

    test('Minor 1000 bricht ab', () {
      expect(
        () => versionFromTag('v0.1000.0'),
        throwsA(isA<InvalidTagException>()),
      );
    });

    test('Patch 1000 bricht ab', () {
      expect(
        () => versionFromTag('v0.1.1000'),
        throwsA(isA<InvalidTagException>()),
      );
    });

    test('Major bis 2099 ist erlaubt, ab 2100 bricht ab (Android-Grenze)', () {
      expect(versionFromTag('v2099.999.999').code, 2099999999);
      expect(
        () => versionFromTag('v2100.0.0'),
        throwsA(isA<InvalidTagException>()),
      );
    });
  });

  group('ohne Tag (lokaler Build)', () {
    test('ergibt 0.0.0-lokal, Code 1 und Flavor dev', () {
      final version = versionFromTag(null);

      expect(version.name, '0.0.0-lokal');
      expect(version.code, 1);
      expect(version.flavor, BuildFlavor.dev);
    });
  });

  group('Dev-Tag', () {
    test('v0.1.0-dev behält den Zusatz im Namen und wählt Flavor dev', () {
      final version = versionFromTag('v0.1.0-dev');

      expect(version.name, '0.1.0-dev');
      expect(version.code, 1000);
      expect(version.flavor, BuildFlavor.dev);
    });
  });
}
