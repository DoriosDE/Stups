import 'package:flutter_test/flutter_test.dart';

import '../../tool/print_version.dart';

void main() {
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    out = StringBuffer();
    err = StringBuffer();
  });

  group('Dev-Tag', () {
    test('wählt den Flavor dev und behält den Zusatz im Namen', () {
      final exitCode = run(['v0.1.0-dev'], out, err);

      expect(exitCode, 0);
      expect(
        out.toString(),
        'name=0.1.0-dev\ncode=1000\nflavor=dev\n'
        'app_id=de.dorios.stups.dev\nlabel=Stups Dev\n',
      );
    });
  });

  group('ohne Tag (lokaler Build)', () {
    const local =
        'name=0.0.0-lokal\ncode=1\nflavor=dev\n'
        'app_id=de.dorios.stups.dev\nlabel=Stups Dev\n';

    test(
      'ein leerer Text steht für „kein Tag“ (so ruft die CI ohne Tag auf)',
      () {
        expect(run([''], out, err), 0);
        expect(out.toString(), local);
      },
    );

    test('ein fehlendes Argument steht ebenfalls für „kein Tag“', () {
      expect(run([], out, err), 0);
      expect(out.toString(), local);
    });
  });

  group('ungültiger Tag', () {
    test(
      'beendet mit Exit-Code 64, nennt den Tag und schreibt nichts auf out',
      () {
        final exitCode = run(['v0.1.0-beta'], out, err);

        expect(exitCode, 64);
        expect(out.toString(), isEmpty);
        expect(err.toString(), contains('v0.1.0-beta'));
        expect(err.toString(), contains('v<Major>.<Minor>.<Patch>'));
      },
    );
  });

  group('Release-Tag', () {
    test('gibt Name, Code und Flavor als schlüssel=wert-Zeilen aus', () {
      final exitCode = run(['v0.1.0'], out, err);

      expect(exitCode, 0);
      expect(
        out.toString(),
        'name=0.1.0\ncode=1000\nflavor=prod\n'
        'app_id=de.dorios.stups\nlabel=Stups\n',
      );
      expect(err.toString(), isEmpty);
    });
  });
}
