import '../../l10n/app_localizations.dart';
import '../db/app_database.dart';

/// Name, den die Oberfläche für [area] zeigt.
///
/// Eigene Bereiche tragen ihren Namen in der Datenbank. Eingebaute Bereiche
/// tragen nur eine Kennung ([BuiltInArea]); ihr Name kommt aus den
/// Sprachdateien. Eine unbekannte Kennung zeigt die Kennung selbst, damit die
/// Oberfläche nicht zerbricht.
String areaDisplayName(AppLocalizations l10n, Area area) {
  final name = area.name;
  if (name != null) return name;
  final key = area.builtInKey!;
  return switch (key) {
    BuiltInArea.household => l10n.areaHousehold,
    BuiltInArea.work => l10n.areaWork,
    BuiltInArea.personal => l10n.areaPersonal,
    _ => key,
  };
}
