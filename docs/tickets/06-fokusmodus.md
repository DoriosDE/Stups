# Ticket 06: Fokusmodus

- **Status:** erledigt
- **Branch:** `feature/fokusmodus`
- **Designprinzip:** Zeit sichtbar machen; Ablenkung parken

## Ziel

Vollbild-Fokus mit Countdown und Ablenkungs-Parkplatz.

## Akzeptanzkriterien

- [x] Vollbild mit Aufgabe, Unterschritten und visuellem Countdown (5, 10, 15 Minuten oder frei)
- [x] Der Countdown beruht auf einem gespeicherten Endzeitpunkt und stimmt auch nach Hintergrundbetrieb
- [x] Ablenkungs-Parkplatz: Einfälle landen in der Inbox
- [x] Bei Zeitende: „Noch 5 Minuten“ oder „Fertig“; jederzeit Ausstieg mit „Für heute reicht’s“
- [x] Widget-Test für den Fokus-Ablauf

## Hinweis

Die Benachrichtigung „Timer-Ende“ kommt in Ticket 07.

Umsetzung und Entscheidungen:

- „Los geht’s“ auf „Heute“ öffnet jetzt den Fokus (`/fokus/:id`) statt der Detailansicht. Dort erst die Dauer wählen (5, 10, 15 Minuten oder „Frei“), dann läuft der Countdown als Ring mit Restzeit.
- Die Sitzung (`FocusSession`) steht samt Endzeitpunkt in der Tabelle `Settings` (Schlüssel `focusSession`); es gibt höchstens eine. Eine Schemaänderung war nicht nötig. Die Restzeit wird bei jedem Tick und beim Zurückkehren aus dem Hintergrund aus der Uhr berechnet, nicht heruntergezählt. Wer den Fokus verlässt und über „Los geht’s“ zurückkommt, findet den laufenden Countdown. Eine Sitzung von gestern gilt als vergessen.
- Der Start legt das Vorkommen von heute mit Status `started` an (`TaskRepository.startToday`). Ein begonnenes Vorkommen macht die Aufgabe nicht zur erledigten: `watchTask` liefert nur erledigte Vorkommen.
- „Fertig“ (bei Zeitende, vorher als leiser Knopf „Schon fertig“) öffnet das Dauer-Blatt, vorbelegt mit der gemessenen Zeit (aufgerundet), erledigt die Aufgabe und feiert. „Noch 5 Minuten“ beginnt bei Zeitende einen neuen Abschnitt.
- „Für heute reicht’s“ steht immer unten im Bild, beendet die Sitzung ohne Vorwurf („Du hast angefangen. Das zählt.“) und lässt die Aufgabe offen im Plan.
- Der Parkplatz schreibt über `FocusRepository.park` in die Inbox (`InboxRepository.add`) und legt eine `DistractionNote` mit dem Vorkommen an.
- „Vollbild“ heißt: eigene Route über dem Rahmen mit Tabs und Plus-Button. Das Display bleibt nicht per Wakelock an.
- Bewusst nicht dabei: Schritte im Fokus abhaken (die Schritte sind nur zu sehen), Hinweis „Timer-Ende“ bei geschlossener App (Ticket 07; dafür liegt der Endzeitpunkt bereits gespeichert vor).
