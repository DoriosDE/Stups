import 'package:material_ui/material_ui.dart';

/// Sprache, die gilt, wenn keine Systemsprache unterstützt wird.
///
/// Heute Deutsch, weil es die einzige Sprache ist. Sobald Englisch
/// dazukommt, wird Englisch der Rückfall: hier auf `Locale('en')` stellen.
const fallbackLocale = Locale('de');

/// Wählt die Sprache der App: die erste Systemsprache, die unterstützt wird
/// (genau oder nur in der Sprache, zum Beispiel de-AT zu de), sonst [fallback].
Locale resolveLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supportedLocales, {
  Locale fallback = fallbackLocale,
}) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == device.languageCode) return supported;
    }
  }
  return fallback;
}
