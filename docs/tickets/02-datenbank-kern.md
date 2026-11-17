# Ticket 02: Datenbank-Kern

- **Status:** offen
- **Branch:** `feature/datenbank-kern`
- **Designprinzip:** Ein System für alles

## Ziel

Das drift-Schema für den Kern ist angelegt und getestet.

## Akzeptanzkriterien

- [ ] Tabellen: Area, InboxItem, Task, Subtask, Occurrence, SubtaskCheck, DayPlan, DistractionNote, Setting
- [ ] UUIDs als Text, Zeitpunkte in UTC, Kalendertage als `yyyy-MM-dd`
- [ ] `Task.recurrence` und `Occurrence` vorhanden; in v0.1 genau eine Occurrence pro einmaliger Aufgabe
- [ ] Standard-Bereiche (Haushalt, Arbeit, Persönliches) werden angelegt
- [ ] Migrationstest und In-Memory-Datenbank für Tests

## Hinweis

Die Wiederholungs-Engine gehört nicht hierher.

## Hinweis zu Paketen

Hier kommen `drift_flutter`, `drift_dev`, `build_runner` und `uuid` in die `pubspec.yaml`. Sie wurden in Ticket 01 bewusst wieder entfernt.
