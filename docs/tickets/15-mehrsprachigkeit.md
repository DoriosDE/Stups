# Ticket 15: Mehrsprachigkeit vorbereiten

- **Status:** in Arbeit
- **Branch:** `feature/mehrsprachigkeit`
- **Designprinzip:** Freundlicher Ton; Barrierearm

## Ziel

Alle Oberflächentexte kommen aus Sprachdateien (ARB). Deutsch ist die erste Sprache, Englisch folgt später ohne Umbau. Das Ticket kommt nach Ticket 02 und vor Ticket 03, damit die ersten echten Texte gleich richtig entstehen.

## Akzeptanzkriterien

- [x] `flutter_localizations` und `intl` sind eingerichtet, ARB-Dateien liegen unter `lib/l10n/`, Deutsch ist die Vorlage; die App folgt der Systemsprache, der Rückfall ist heute Deutsch und soll Englisch werden, sobald Englisch da ist
- [x] Alle bisherigen Texte (Tab-Namen, Platzhalter, Plus-Button-Hinweis, Versionsanzeige) kommen aus den Sprachdateien
- [x] Die Anzeigenamen der eingebauten Bereiche (`household`, `work`, `personal`) stehen in den Sprachdateien; `name` der Area-Tabelle überschreibt sie nur bei eigenen Bereichen
- [x] Ein Test stellt sicher, dass kein Text aus der Sprachdatei zusätzlich als Literal in `lib/` steht (Grenze: ein ganz neuer, nie eingetragener Text fällt dem Test nicht auf)
- [x] Die Texte folgen den Regeln aus CLAUDE.md (Du-Form, kurz, ermutigend)
- [x] Doku: Wie man einen neuen Text oder eine neue Sprache hinzufügt (CLAUDE.md oder README)

## Hinweise

- Vorlagen (Routinen, Raumpakete, Challenges) liegen später als JSON in den Assets; ihre Texte müssen ebenfalls über Sprachdateien laufen. Das Format legt das Ticket zu den Routinen fest.
- Die Datenbank bleibt sprachneutral (siehe Ticket 02).

## Entscheidungen

- Erzeugter Sprachcode (`lib/l10n/app_localizations*.dart`) liegt nicht im Git, er entsteht bei `flutter pub get`.
- Nur Deutsch jetzt; die Mechanik belegt ein Test mit einer Test-Übersetzung, die jeden Text durch einen Marker ersetzt.
- Die App folgt der Systemsprache. Der Rückfall ist in `lib/core/l10n/locale_resolution.dart` festgelegt (heute Deutsch, später Englisch).
- Seitentitel verwenden die Texte der Tab-Namen (`tabToday` und so weiter).

## Umsetzungsstand

Testgetrieben in vier Seams: (1) Texte kommen aus den Sprachdateien (Test-Übersetzung mit Markern: Tabs, Seitentitel und Hinweise, Plus-Button-Hinweis, Versionsanzeige, App-Titel), (2) `areaDisplayName`, (3) Wächter gegen feste Texte samt Beschreibungspflicht für Schlüssel, (4) Sprachauswahl mit Rückfall (`resolveLocale`). Der vierte Seam ist aus der Vorgabe zum Rückfall entstanden. Die Gegenprobe zum Wächter wurde gemacht: Mit einem festen Text im Code schlägt er an.

Beim Umsetzen aufgefallen: Der erzeugte `AppLocalizations.localizationsDelegates` nimmt die veraltete `GlobalMaterialLocalizations` aus `flutter_localizations`; zu `MaterialApp` aus `material_ui` passt die aus `material_ui`. Deshalb stellt `appLocalizationsDelegates` die Delegates selbst zusammen (siehe HANDOFF, „Sprachen“).

Nicht getestet: der Wortlaut der deutschen Texte (Review) und die Verdrahtung der Sprachauswahl in `StupsApp` (mit nur einer Sprache wählt Flutter von selbst dasselbe; der Test dafür kommt mit der zweiten Sprache).
