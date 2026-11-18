# Ticket 05: Heute

- **Status:** erledigt
- **Branch:** `feature/heute`
- **Designprinzip:** Tagesform berücksichtigen; Sofort belohnen; Sichtbar am Ort des Handelns

## Ziel

„Heute“ zeigt nach dem Energie-Check nur den nächsten Schritt.

## Akzeptanzkriterien

- [x] Energie-Check (wenig, mittel, viel) wählt 1, 2 oder 3 Aufgaben: A vor B vor C, nach Fälligkeit, höchstens 3
- [x] Ohne Aufgaben: „Alles ruhig. Magst du Kopf frei machen?“
- [x] Groß nur der nächste Schritt mit „Los geht’s“, Rest eingeklappt
- [x] Nicht erledigte Aufgaben verfallen aus dem Tagesplan, keine Überfällig-Liste, höchstens „Morgen nochmal?“
- [x] Feier nach Erledigen: Haptik, Konfetti, Taten-Zähler (aus Occurrences berechnet); abschaltbar und verträglich mit „Bewegung reduzieren“
- [x] Begleiter (Staubwölkchen) bei Begrüßung und Erfolg, mit frei wählbarem Namen, abschaltbar
- [x] Tagesplan-Logik testgetrieben, Widget-Test für Heute

## Hinweise

- Der Claim „Rein ins Tun.“ steht im Prototyp unter dem Namen im Kopfbereich. Wird er eingebaut, kommt er aus den Sprachdateien; die englische Fassung wird dann festgelegt (siehe Ticket 16).
- „Los geht’s“ öffnete zunächst die Detailansicht der Aufgabe; seit Ticket 06 öffnet es den Fokusmodus.
- „Abschaltbar“ heißt: „Animationen reduzieren“ (kein Konfetti, keine Bewegung) und „Vibrieren bei Erfolgen“ in den neuen Einstellungen unter „Mehr“; dazu zeigt die Feier ohne Konfetti, wenn das System „Bewegung reduzieren“ meldet. Der Begleiter hat einen eigenen Schalter und einen Namen.
- Eine Aufgabe, die man mit „Morgen nochmal?“ aus dem Plan nimmt, kann nach „Energie ändern“ wieder auftauchen; der Plan merkt sich nur die gewählten, nicht die abgelehnten Aufgaben.
- Der heutige Tag wechselt um Mitternacht von selbst (`todayKeyProvider` mit Timer); der Plan gilt je Kalendertag.
- Was heute außerhalb des Plans erledigt wurde, zählt nicht zur Planmenge: „Energie ändern“ behält nur erledigte Aufgaben, die im Plan standen.
