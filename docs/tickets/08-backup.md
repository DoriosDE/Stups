# Ticket 08: JSON-Backup

- **Status:** offen
- **Branch:** `feature/backup`
- **Designprinzip:** Offene Daten, volle Kontrolle (Ziel: offline-first)

## Ziel

Export und Import aller Daten als JSON-Datei.

## Akzeptanzkriterien

- [ ] Export mit `schemaVersion` über das Teilen-Menü
- [ ] Import ersetzt nach Bestätigung alle Daten, vorher automatische Sicherheitskopie
- [ ] Roundtrip-Test: Export, Import, identische Daten
- [ ] Einstellungen: Export, Import, alles zurücksetzen

## Hinweis zum Fokusmodus (Ticket 06)

Die laufende Fokus-Sitzung steht in der Tabelle `Settings` unter dem Schlüssel `focusSession` (JSON mit `taskId`, `occurrenceId` und Zeitpunkten). Sie ist flüchtiger Zustand, kein Nutzerinhalt. Vorschlag:

- Der Export lässt den Schlüssel `focusSession` aus: Eine Sicherung soll keinen laufenden Countdown mitnehmen.
- Der Import entfernt ihn, damit nach dem Einspielen keine Sitzung auftaucht, die auf nicht mehr vorhandene Vorkommen zeigt.
- „Alles zurücksetzen“ löscht ihn mit den übrigen Einstellungen. Ein Test dafür gehört in das Ticket (Sitzung starten, zurücksetzen, es gibt keine Sitzung mehr).
- Die Haken bei Schritten (`SubtaskChecks`) und die Ablenkungs-Notizen (`DistractionNotes`) sind dagegen Nutzerdaten und gehören in den Export.

## Hinweis zu Paketen

Hier kommen `share_plus`, `file_picker` und `path_provider` in die `pubspec.yaml`.
