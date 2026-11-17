import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Alle Sprachdateien haben dieselben Schlüssel und Platzhalter wie
/// die Vorlage (Deutsch). Das fängt vergessene oder überzählige Texte; den
/// Wortlaut prüft das Review.
void main() {
  Map<String, dynamic> read(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  Set<String> keys(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  // Platzhalter stehen im Text selbst (`{version}`); Metadaten braucht nur die
  // Vorlage.
  Set<String> placeholders(Map<String, dynamic> arb, String key) => {
    for (final match in RegExp(r'\{(\w+)\}').allMatches(arb[key] as String))
      match.group(1)!,
  };

  final template = read(File('lib/l10n/app_de.arb'));
  final others = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) {
        final name = file.uri.pathSegments.last;
        return name.endsWith('.arb') && name != 'app_de.arb';
      })
      .toList();

  test('es gibt mindestens eine weitere Sprache neben Deutsch', () {
    expect(others, isNotEmpty);
  });

  for (final file in others) {
    final name = file.uri.pathSegments.last;
    final arb = read(file);

    test('$name hat genau die Schlüssel der Vorlage', () {
      expect(
        keys(arb).difference(keys(template)),
        isEmpty,
        reason: 'Überzählig in $name',
      );
      expect(
        keys(template).difference(keys(arb)),
        isEmpty,
        reason: 'Fehlt in $name',
      );
    });

    test('$name hat dieselben Platzhalter wie die Vorlage', () {
      for (final key in keys(template)) {
        expect(
          placeholders(arb, key),
          placeholders(template, key),
          reason: 'Platzhalter von $key in $name',
        );
      }
    });
  }
}
