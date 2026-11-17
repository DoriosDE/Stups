import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Seam 3: Sicherung gegen feste Texte im Code.
///
/// Kein Text aus der Sprachdatei darf zusätzlich als Text-Literal im Code
/// stehen. Grenze: Ein ganz neuer Text, der nie in die Sprachdatei kommt,
/// fällt hier nicht auf; das fängt das Review. Texte mit Platzhaltern
/// (`{version}`) werden nicht verglichen.
void main() {
  final arb = jsonDecode(
    File('lib/l10n/app_de.arb').readAsStringSync(),
  ) as Map<String, dynamic>;

  final messages = {
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
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

  test('jeder Schlüssel in der Sprachdatei hat eine Beschreibung', () {
    final missing = [
      for (final key in messages.keys)
        if (((arb['@$key'] as Map<String, dynamic>?)?['description']
                    as String? ??
                '')
            .isEmpty)
          key,
    ];

    expect(missing, isEmpty, reason: 'Ohne Beschreibung: $missing');
  });
}
