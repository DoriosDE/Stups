# Ticket 01: Grundlage

- **Status:** in Arbeit
- **Branch:** `feature/projekt-grundlage`
- **Designprinzip:** Barrierearm; Eine Sache pro Bildschirm

## Ziel

Repo und Flutter-Projekt stehen, CI läuft, Theme und 5-Tab-Gerüst sind da.

## Akzeptanzkriterien

- [x] Docs, Prototyp und Apache-2.0-Lizenz sind im Repo
- [x] Flutter-Projekt `stups` mit App-ID `de.dorios.stups`, Android 8+ (minSdk 26)
- [x] Abhängigkeiten: Riverpod (ohne Generator), drift, go_router, flutter_local_notifications, timezone
- [ ] GitHub Actions: Analyse, Tests, Debug-Build (Workflow liegt vor, ist aber noch nicht auf GitHub gelaufen)
- [x] Theme aus den Design-Tokens (hell und dunkel), Fredoka und Lexend gebündelt
- [x] go_router mit 5 Tabs (Heute, Aufgaben, Routinen, Haushalt, Mehr) und schwebendem Plus-Button
- [x] `flutter analyze` und `flutter test` laufen grün

## Hinweis

Beginnt mit Docs, Lizenz und Tickets; das Flutter-Gerüst folgt in eigenen Commits.

Lokal bestätigt: `flutter build apk --debug` läuft durch. Dafür waren nötig: `compileSdk = 37` und Core-Library-Desugaring (`flutter_local_notifications`), `kotlin.incremental=false` (Pub-Cache auf C:, Projekt auf D:) und ein JDK 17 oder neuer für Flutter (`flutter config --jdk-dir`). Offen bis zum Abschluss: erster grüner CI-Lauf auf GitHub. Danach den Status auf `erledigt` setzen.

Auf einem Android-17-Gerät (API 37) geprüft: Kaltstart auf „Heute“, Wechsel zwischen den Tabs, Hell- und Dunkelmodus, Fredoka (Überschriften, Gewicht 700) und Lexend (Text) werden richtig dargestellt, Systemschriftgröße 1,8 ohne Überlauf. Bei 1,8 stehen die Tab-Beschriftungen „Aufgaben“ und „Routinen“ eng nebeneinander; das beobachten wir bei weiteren Screens. Der Plus-Button ist bewusst noch ohne Funktion (Ticket 03).
