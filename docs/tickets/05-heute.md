# Ticket 05: Heute

- **Status:** offen
- **Branch:** `feature/heute`
- **Designprinzip:** Tagesform berücksichtigen; Sofort belohnen; Sichtbar am Ort des Handelns

## Ziel

„Heute“ zeigt nach dem Energie-Check nur den nächsten Schritt.

## Akzeptanzkriterien

- [ ] Energie-Check (wenig, mittel, viel) wählt 1, 2 oder 3 Aufgaben: A vor B vor C, nach Fälligkeit, höchstens 3
- [ ] Ohne Aufgaben: „Alles ruhig. Magst du Kopf frei machen?“
- [ ] Groß nur der nächste Schritt mit „Los geht’s“, Rest eingeklappt
- [ ] Nicht erledigte Aufgaben verfallen aus dem Tagesplan, keine Überfällig-Liste, höchstens „Morgen nochmal?“
- [ ] Feier nach Erledigen: Haptik, Konfetti, Taten-Zähler (aus Occurrences berechnet); abschaltbar und verträglich mit „Bewegung reduzieren“
- [ ] Begleiter (Staubwölkchen) bei Begrüßung und Erfolg, mit frei wählbarem Namen, abschaltbar
- [ ] Tagesplan-Logik testgetrieben, Widget-Test für Heute

## Hinweise

- Der Claim „Rein ins Tun.“ steht im Prototyp unter dem Namen im Kopfbereich. Wird er eingebaut, kommt er aus den Sprachdateien; die englische Fassung wird dann festgelegt (siehe Ticket 16).
