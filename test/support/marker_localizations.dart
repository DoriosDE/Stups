import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
import 'package:stups/l10n/app_localizations.dart';

/// Test-Übersetzung: Jeder Text erscheint als Marker `⟦schlüssel⟧` (mit
/// Argumenten `⟦schlüssel:wert⟧`). Steht ein Text irgendwo fest im Code, fehlt
/// sein Marker in der Oberfläche.
class MarkerLocalizations extends AppLocalizations {
  MarkerLocalizations() : super('de');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = RegExp(r'"([^"]+)"')
        .firstMatch(invocation.memberName.toString())!
        .group(1)!;
    final args = invocation.positionalArguments;
    return args.isEmpty ? marker(name) : marker(name, args.join(','));
  }
}

/// Der Marker, den [MarkerLocalizations] für [key] liefert.
String marker(String key, [String? argument]) =>
    argument == null ? '⟦$key⟧' : '⟦$key:$argument⟧';

class _MarkerDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _MarkerDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(MarkerLocalizations());

  @override
  bool shouldReload(_MarkerDelegate old) => false;
}

/// Delegates für `MaterialApp`, die statt der echten Texte die Marker liefern.
const markerLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  _MarkerDelegate(),
  ...GlobalMaterialLocalizations.delegates,
];
