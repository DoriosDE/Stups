import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/l10n/locale_resolution.dart';

/// Seam 4: Welche Sprache die App wählt. Sie folgt der Systemsprache; ist sie
/// nicht dabei, gilt der Rückfall (Englisch).
void main() {
  const de = Locale('de');
  const en = Locale('en');

  group('Systemsprache wird unterstützt', () {
    test('de-DE ergibt de', () {
      expect(resolveLocale(const [Locale('de', 'DE')], const [de]), de);
    });

    test('eine Regionsvariante wie de-AT ergibt de', () {
      expect(resolveLocale(const [Locale('de', 'AT')], const [de]), de);
    });

    test('bei mehreren Sprachen gewinnt die passende, nicht die erste', () {
      expect(resolveLocale(const [Locale('en', 'US')], const [de, en]), en);
    });

    test('es zählt die Reihenfolge der Systemsprachen', () {
      expect(resolveLocale(const [Locale('fr'), Locale('de')], const [de]), de);
      expect(
        resolveLocale(const [Locale('en'), Locale('de')], const [de, en]),
        en,
      );
    });
  });

  group('Rückfall', () {
    test('eine nicht unterstützte Sprache ergibt den Rückfall', () {
      expect(
        resolveLocale(const [Locale('fr')], const [de, en], fallback: en),
        en,
      );
      expect(
        resolveLocale(const [Locale('fr')], const [de, en], fallback: de),
        de,
      );
    });

    test('ohne Systemsprachen ergibt der Rückfall', () {
      expect(resolveLocale(null, const [de, en], fallback: en), en);
      expect(resolveLocale(const [], const [de, en], fallback: en), en);
    });

    test('der Rückfall der App ist Englisch', () {
      expect(resolveLocale(const [Locale('fr')], const [de, en]), en);
      expect(fallbackLocale, en);
    });
  });
}
