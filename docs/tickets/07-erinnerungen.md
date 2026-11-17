# Ticket 07: Erinnerungen (Stupser)

- **Status:** offen
- **Branch:** `feature/erinnerungen`
- **Designprinzip:** Sichtbar am Ort des Handelns

## Ziel

Lokale Erinnerungen über die Schnittstelle `ReminderService`.

## Akzeptanzkriterien

- [ ] Schnittstelle `ReminderService` mit Android-Implementierung und Web-No-op
- [ ] Tagesstart-Erinnerung (Standard 8:30, einstellbar) und Timer-Ende
- [ ] Rollendes Fenster von 14 Tagen, unter 50 Einträgen, nächstgelegene zuerst; Ruhezeiten (Standard 22:00 bis 7:00)
- [ ] Neu planen bei App-Start, Änderung, Neustart und Zeitzonenwechsel
- [ ] Berechtigungsabfrage mit Erklärung; ohne Berechtigung ein freundlicher Hinweis in „Heute“
- [ ] Exakter Alarm (Android 14+) erst beim ersten Timer-Start erklärt und abgefragt, sonst ungenauer Alarm
- [ ] Aktionen in der Benachrichtigung: „Erledigt“, „Später“ (1 Stunde), „Fokus starten“
- [ ] Planungslogik testgetrieben mit Fake-Dienst
