# Ticket 02: Datenbank-Kern

- **Status:** in Arbeit
- **Branch:** `feature/datenbank-kern`
- **Designprinzip:** Ein System für alles

## Ziel

Das drift-Schema für den Kern ist angelegt und getestet. Die Datenbank ist sprachneutral: Texte, die die App mitbringt, stehen nicht in der Datenbank.

## Akzeptanzkriterien

- [x] Tabellen: Area, InboxItem, Task, Subtask, Occurrence, SubtaskCheck, DayPlan, DistractionNote, Setting
- [x] UUIDs als Text, Zeitpunkte in UTC, Kalendertage als `yyyy-MM-dd` (das Format wird per `CHECK` erzwungen)
- [x] Standard-Bereiche (Haushalt, Arbeit, Persönliches) werden beim Anlegen der Datenbank eingetragen, als `builtInKey` `household`, `work`, `personal`, ohne Namen; der Anzeigename kommt später aus den Sprachdateien (Ticket 15)
- [x] `Area`: `builtInKey` (eindeutig, bei eigenen Bereichen leer) und `name` (nur bei eigenen Bereichen); `CHECK`: eines von beiden ist gesetzt; `hidden` zum Ein- und Ausblenden
- [x] `Occurrence.date` ist Pflicht, pro `(taskId, date)` höchstens eine Occurrence; wann sie entsteht (erst beim Starten, Erledigen, Verschieben oder Auslassen), setzt die Aufgabenlogik in Ticket 04 um
- [x] Fremdschlüssel sind eingeschaltet: Löschen einer Aufgabe entfernt Unterschritte, Vorkommen und Häkchen (Cascade); ein Bereich mit Aufgaben lässt sich nicht löschen (Restrict)
- [x] `Task.recurrence` und `DayPlan.plannedTaskIds` sind vorerst JSON als Text
- [ ] Die erzeugten `*.g.dart`-Dateien sind nicht im Git; CI und Doku führen `build_runner` aus (Doku und Workflow stehen, der CI-Lauf auf GitHub fehlt noch)
- [x] Migrations-Sicherheitsnetz: JSON-Schnappschuss des Schemas v1 unter `drift_schemas/` und ein Test, der prüft, dass die Datenbank dazu passt
- [x] In-Memory-Datenbank für Tests

## Entscheidungen

- Eingebaute Bereiche lassen sich nur ein- und ausblenden, nicht umbenennen oder löschen; eigene Bereiche sind frei benennbar. Das setzen Repository und Oberfläche durch (Ticket 04), das Schema verhindert nur das Löschen von Bereichen mit Aufgaben.
- Die Wiederholungs-Engine gehört nicht hierher.
- `Task.priority` ist Pflicht mit Standard B; Ticket 04 kann das ändern. `Task.createdAt` ist hinzugekommen (Sortierung, Rückblick) und steht jetzt in der SPEC.
- `Occurrence.status` kennt `open` (angelegt, noch nichts passiert), `started`, `done`, `postponed` und `skipped`. `DayPlan.energy` kennt `low`, `medium` und `high`.
- `DistractionNote.occurrenceId` ist optional; wird das Vorkommen gelöscht, bleibt die Notiz bestehen (`SET NULL`).
- Zeitpunkte speichert drift als absolute Zeit; das Schema erzwingt kein UTC, der Code übergibt UTC (`nowUtc()`). Das Tagesformat prüft nur die Form, nicht ob der Tag existiert.
- Typisierte Konverter für die JSON-Spalten folgen, wenn sie gebraucht werden: bei der Wiederholungs-Engine (v0.2) und bei „Heute“ (Ticket 05).

## Hinweis zu Paketen

Hier kommen `drift_flutter`, `drift_dev`, `build_runner` und `uuid` in die `pubspec.yaml`. Sie wurden in Ticket 01 bewusst wieder entfernt.

## Umsetzungsstand

Testgetrieben in zwei Seams umgesetzt: Seam 1, das Schema von Grund auf (28 Tests: Standard-Bereiche, Regeln für Bereiche, Standardwerte und UUIDs, Fremdschlüssel mit Cascade und Restrict, Eindeutigkeit, Datumsformat), und Seam 2, das Migrations-Sicherheitsnetz (`test/core/db/schema_snapshot_test.dart` mit dem Schnappschuss `drift_schemas/drift_schema_v1.json`). Die Gegenprobe wurde gemacht: Mit einer zusätzlichen Spalte schlägt der Schnappschuss-Test fehl, ohne sie ist er grün.

Zwei Dinge, die beim Umsetzen auffielen (beide in HANDOFF, Abschnitt „Datenbank“, festgehalten):
- `CHECK`-Regeln müssen als Text-Literale in der Tabelle stehen, sonst fehlen sie im Schnappschuss.
- Der erste Entwurf des Schnappschuss-Tests war wirkungslos (er verglich einen aus dem Schnappschuss erzeugten Stand mit sich selbst); die Gegenprobe hat das aufgedeckt, der Test legt die Datenbank jetzt aus dem Code an.

Nicht per Unit-Test geprüft, wie vereinbart: der Provider `appDatabaseProvider` und die Datei auf dem Gerät. Die App öffnet die Datenbank noch nirgends; das geschieht erstmals mit Ticket 03 (dann auch Gerätetest). Die Debug-App baut und startet mit den neuen Paketen.
