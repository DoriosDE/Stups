import '../db/app_database.dart';

/// Die Einstellungen, die die Oberfläche braucht.
class AppSettings {
  const AppSettings({
    this.companionName,
    this.showCompanion = true,
    this.haptics = true,
    this.reduceAnimations = false,
  });

  /// Der Name, den die Person dem Begleiter gab. `null` heißt: Standardname
  /// aus den Sprachdateien, damit er mit der Sprache mitwandert.
  final String? companionName;
  final bool showCompanion;

  /// Kurzes Vibrieren bei Erfolgen.
  final bool haptics;

  /// Keine Bewegung bei der Feier, zusätzlich zur Systemeinstellung „Bewegung
  /// reduzieren“.
  final bool reduceAnimations;
}

/// Einstellungen als Schlüssel-Wert-Paare in der Tabelle `Settings`.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _companionName = 'companionName';
  static const _showCompanion = 'showCompanion';
  static const _haptics = 'haptics';
  static const _reduceAnimations = 'reduceAnimations';

  Stream<AppSettings> watch() {
    return _db.select(_db.settings).watch().map((rows) {
      final values = {for (final row in rows) row.key: row.value};
      bool flag(String key, bool fallback) =>
          values[key] == null ? fallback : values[key] == 'true';
      return AppSettings(
        companionName: values[_companionName],
        showCompanion: flag(_showCompanion, true),
        haptics: flag(_haptics, true),
        reduceAnimations: flag(_reduceAnimations, false),
      );
    });
  }

  /// Ohne Leerraum am Rand; leer oder `null` heißt wieder Standardname.
  Future<void> setCompanionName(String? name) async {
    final clean = name?.trim() ?? '';
    if (clean.isEmpty) {
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.equals(_companionName))).go();
    } else {
      await _set(_companionName, clean);
    }
  }

  Future<void> setShowCompanion(bool value) =>
      _set(_showCompanion, value.toString());

  Future<void> setHaptics(bool value) => _set(_haptics, value.toString());

  Future<void> setReduceAnimations(bool value) =>
      _set(_reduceAnimations, value.toString());

  Future<void> _set(String key, String value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }
}
