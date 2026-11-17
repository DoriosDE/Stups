# Ticket 01: Grundlage

- **Status:** in Arbeit
- **Branch:** `feature/projekt-grundlage`
- **Designprinzip:** Barrierearm; Eine Sache pro Bildschirm

## Ziel

Repo und Flutter-Projekt stehen, CI läuft, Theme und 5-Tab-Gerüst sind da.

## Akzeptanzkriterien

- [ ] Docs, Prototyp und Apache-2.0-Lizenz sind im Repo
- [ ] Flutter-Projekt `stups` mit App-ID `de.dorios.stups`, Android 8+ (minSdk 26)
- [ ] Abhängigkeiten: Riverpod (ohne Generator), drift, go_router, flutter_local_notifications, timezone
- [ ] GitHub Actions: Analyse, Tests, Debug-Build
- [ ] Theme aus den Design-Tokens (hell und dunkel), Fredoka und Lexend gebündelt
- [ ] go_router mit 5 Tabs (Heute, Aufgaben, Routinen, Haushalt, Mehr) und schwebendem Plus-Button
- [ ] `flutter analyze` und `flutter test` laufen grün

## Hinweis

Beginnt mit Docs, Lizenz und Tickets; das Flutter-Gerüst folgt in eigenen Commits.
