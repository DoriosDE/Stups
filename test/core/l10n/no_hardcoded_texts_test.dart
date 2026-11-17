import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Seam 3: Sicherung gegen feste Texte im Code.
///
/// Kein Text aus einer Sprachdatei (alle Sprachen) darf zusätzlich als
/// Text-Literal im Code stehen. Grenze: Ein ganz neuer Text, der nie in die Sprachdatei kommt,
/// fällt hier nicht auf; das fängt das Review. Texte mit Platzhaltern
/// (`{version}`) werden nicht verglichen.
void main() {
  Map<String, dynamic> read(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final files = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();
  final arb = read(File('lib/l10n/app_de.arb'));

  // Alle Texte aller Sprachen: (Datei, Schlüssel) -> Text.
  final messages = {
    for (final file in files)
      for (final entry in read(file).entries)
        if (!entry.key.startsWith('@'))
          '${file.uri.pathSegments.last}/${entry.key}': entry.value as String,
  };

  test('kein Text aus der Sprachdatei steht fest im Code', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final path = file.path.replaceAll(r'\', '/');
          return path.endsWith('.dart') && !path.startsWith('lib/l10n/');
        })
        .toList();
    expect(sources, isNotEmpty);

    final violations = <String>[];
    for (final file in sources) {
      final code = file.readAsStringSync();
      for (final MapEntry(key: key, value: text) in messages.entries) {
        if (text.contains('{')) continue;
        if (code.contains("'$text'") || code.contains('"$text"')) {
          violations.add('${file.path}: "$text" (Schlüssel $key)');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('jeder Schlüssel der Vorlage (Deutsch) hat eine Beschreibung', () {
    final missing = [
      for (final key in arb.keys.where((key) => !key.startsWith('@')))
        if (((arb['@$key'] as Map<String, dynamic>?)?['description']
                    as String? ??
                '')
            .isEmpty)
          key,
    ];

    expect(missing, isEmpty, reason: 'Ohne Beschreibung: $missing');
  });
}
