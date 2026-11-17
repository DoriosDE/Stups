# Ticket 15: Mehrsprachigkeit vorbereiten

- **Status:** offen
- **Branch:** `feature/mehrsprachigkeit`
- **Designprinzip:** Freundlicher Ton; Barrierearm

## Ziel

Alle Oberflächentexte kommen aus Sprachdateien (ARB). Deutsch ist die erste Sprache, Englisch folgt später ohne Umbau. Das Ticket kommt nach Ticket 02 und vor Ticket 03, damit die ersten echten Texte gleich richtig entstehen.

## Akzeptanzkriterien

- [ ] `flutter_localizations` und `intl` sind eingerichtet, ARB-Dateien liegen unter `lib/l10n/`, Deutsch ist die Vorlage
- [ ] Alle bisherigen Texte (Tab-Namen, Platzhalter, Plus-Button-Hinweis, Versionsanzeige) kommen aus den Sprachdateien
- [ ] Die Anzeigenamen der eingebauten Bereiche (`household`, `work`, `personal`) stehen in den Sprachdateien; `name` der Area-Tabelle überschreibt sie nur bei eigenen Bereichen
- [ ] Ein Test stellt sicher, dass in `lib/` kein deutscher Oberflächentext mehr fest im Code steht (Stichproben der bekannten Texte)
- [ ] Die Texte folgen den Regeln aus CLAUDE.md (Du-Form, kurz, ermutigend)
- [ ] Doku: Wie man einen neuen Text oder eine neue Sprache hinzufügt (CLAUDE.md oder README)

## Hinweise

- Vorlagen (Routinen, Raumpakete, Challenges) liegen später als JSON in den Assets; ihre Texte müssen ebenfalls über Sprachdateien laufen. Das Format legt das Ticket zu den Routinen fest.
- Die Datenbank bleibt sprachneutral (siehe Ticket 02).
