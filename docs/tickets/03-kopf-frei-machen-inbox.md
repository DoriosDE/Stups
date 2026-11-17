# Ticket 03: Kopf frei machen und Inbox

- **Status:** erledigt
- **Branch:** `feature/kopf-frei-machen-inbox`
- **Designprinzip:** Ablenkung parken; Ein System für alles

## Ziel

Der Plus-Button erfasst Gedanken ohne Kategorie in der Inbox.

## Akzeptanzkriterien

- [x] Plus-Button öffnet ein Eingabefeld, „Fertig“ speichert
- [x] Spracheingabe über die Diktierfunktion des Systems
- [x] Inbox-Ansicht; ein Eintrag wird zur Aufgabe oder gelöscht (Routine folgt in v0.2)
- [x] Texte nutzen die Du-Form und sind kurz
- [x] Widget-Test für den Erfassen-Ablauf

Setzt Ticket 15 (Mehrsprachigkeit vorbereiten) voraus: neue Texte entstehen gleich in den Sprachdateien.

## Hinweise

- **Spracheingabe** läuft über das Mikrofon der Systemtastatur. Das Eingabefeld ist ein gewöhnliches Textfeld; einen eigenen Mikrofon-Knopf und ein Plugin gibt es bewusst nicht (keine Berechtigung, keine Abhängigkeit, F-Droid bleibt möglich). Der Prototyp zeigt einen Mikrofon-Knopf; er ist hier nur Optik.
- **„Zur Aufgabe“** legt die Aufgabe im Bereich „Persönliches“ mit Priorität B an (so macht es der Prototyp). Erster Schritt, Dauer, Bereich und Fälligkeit ergänzt Ticket 04. Der Eintrag verlässt die Inbox im selben Schritt (eine Transaktion).
- **Inbox-Ansicht:** Sie steht oben im Tab „Aufgaben“. Die Umschaltung zwischen „Inbox“ und „Alle Aufgaben“ (Prototyp) kommt mit Ticket 04, wenn es die Aufgabenliste gibt.
- Die Inbox zeigt den ältesten Gedanken zuerst. „Fertig“ ist gesperrt, solange nur Leerraum im Feld steht; gespeichert wird der Text ohne Leerraum am Rand.
- Der Platzhalter `tasksHint` im Tab „Aufgaben“ entfällt.
- Der Weg „Eintrag wird zur Routine“ (SPEC) fehlt bewusst; er folgt mit den Routinen in v0.2.
- Der Ablenkungs-Parkplatz im Fokusmodus (Ticket 06) nutzt `InboxRepository.add`.

## Umsetzungsstand

Testgetrieben an vier Seams, vorab abgestimmt: `inbox_repository_test.dart` (Datenlogik mit In-Memory-Datenbank: Erfassen mit Trimmen, leere Eingaben, Reihenfolge, Löschen, „Zur Aufgabe“), `capture_flow_test.dart` (Plus-Button, Eingabe, „Fertig“, Sperre bei leerem Feld, Bestätigung), `inbox_view_test.dart` (Leerzustand, Liste, Löschen, „Zur Aufgabe“ mit Meldung) und `localized_texts_test.dart` (alle neuen Texte kommen aus den Sprachdateien; Marker).

Gegenprobe: Ein fester Text statt `l10n.inboxIntro` lässt den Marker-Test anschlagen; eine umgedrehte Sortierung lässt den Reihenfolge-Test anschlagen.

Nicht getestet: der Wortlaut der Texte (Review), das Aussehen und die echte Diktierfunktion auf dem Gerät.
