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

## Hinweis zu Paketen

Hier kommen `share_plus`, `file_picker` und `path_provider` in die `pubspec.yaml`.
