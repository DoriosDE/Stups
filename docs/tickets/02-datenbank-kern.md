# Ticket 02: Datenbank-Kern

- **Status:** in Arbeit
- **Branch:** `feature/datenbank-kern`
- **Designprinzip:** Ein System für alles

## Ziel

Das drift-Schema für den Kern ist angelegt und getestet. Die Datenbank ist sprachneutral: Texte, die die App mitbringt, stehen nicht in der Datenbank.

## Akzeptanzkriterien

- [ ] Tabellen: Area, InboxItem, Task, Subtask, Occurrence, SubtaskCheck, DayPlan, DistractionNote, Setting
- [ ] UUIDs als Text, Zeitpunkte in UTC, Kalendertage als `yyyy-MM-dd` (das Format wird per `CHECK` erzwungen)
- [ ] Standard-Bereiche (Haushalt, Arbeit, Persönliches) werden beim Anlegen der Datenbank eingetragen, als `builtInKey` `household`, `work`, `personal`, ohne Namen; der Anzeigename kommt später aus den Sprachdateien (Ticket 15)
- [ ] `Area`: `builtInKey` (eindeutig, bei eigenen Bereichen leer) und `name` (nur bei eigenen Bereichen); `CHECK`: eines von beiden ist gesetzt; `hidden` zum Ein- und Ausblenden
- [ ] `Occurrence.date` ist Pflicht, pro `(taskId, date)` höchstens eine Occurrence; wann sie entsteht (erst beim Starten, Erledigen, Verschieben oder Auslassen), setzt die Aufgabenlogik in Ticket 04 um
- [ ] Fremdschlüssel sind eingeschaltet: Löschen einer Aufgabe entfernt Unterschritte, Vorkommen und Häkchen (Cascade); ein Bereich mit Aufgaben lässt sich nicht löschen (Restrict)
- [ ] `Task.recurrence` und `DayPlan.plannedTaskIds` sind vorerst JSON als Text
- [ ] Die erzeugten `*.g.dart`-Dateien sind nicht im Git; CI und Doku führen `build_runner` aus
- [ ] Migrations-Sicherheitsnetz: JSON-Schnappschuss des Schemas v1 unter `drift_schemas/` und ein Test, der prüft, dass die Datenbank dazu passt
- [ ] In-Memory-Datenbank für Tests

## Entscheidungen

- Eingebaute Bereiche lassen sich nur ein- und ausblenden, nicht umbenennen oder löschen; eigene Bereiche sind frei benennbar. Das setzen Repository und Oberfläche durch (Ticket 04), das Schema verhindert nur das Löschen von Bereichen mit Aufgaben.
- Die Wiederholungs-Engine gehört nicht hierher.
- Typisierte Konverter für die JSON-Spalten folgen, wenn sie gebraucht werden: bei der Wiederholungs-Engine (v0.2) und bei „Heute“ (Ticket 05).

## Hinweis zu Paketen

Hier kommen `drift_flutter`, `drift_dev`, `build_runner` und `uuid` in die `pubspec.yaml`. Sie wurden in Ticket 01 bewusst wieder entfernt.
