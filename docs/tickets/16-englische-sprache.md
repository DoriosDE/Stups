# Ticket 16: Englische Sprache

- **Status:** erledigt
- **Branch:** `feature/englisch`
- **Designprinzip:** Freundlicher Ton; Barrierearm

## Ziel

Die App gibt es auch auf Englisch. Sie folgt der Systemsprache; ist weder Deutsch noch Englisch eingestellt, gilt Englisch. Ticket 15 hat die Mechanik vorbereitet, dieses Ticket fügt die Sprache hinzu.

## Akzeptanzkriterien

- [x] `lib/l10n/app_en.arb` enthält genau die Schlüssel von `app_de.arb` mit denselben Platzhaltern; ein Test sichert das
- [x] Bei Systemsprache Englisch zeigt die App Tabs, Hinweise, Plus-Button-Hinweis und Versionsanzeige auf Englisch; bei Deutsch bleibt alles Deutsch (Test der Sprachverdrahtung in `StupsApp`)
- [x] Der Rückfall (`fallbackLocale`) ist Englisch; eine nicht unterstützte Sprache ergibt Englisch, `de-AT` bleibt Deutsch
- [x] Die eingebauten Bereiche heißen auf Englisch „Home“, „Work“ und „Personal“
- [x] Der Wächter gegen feste Texte prüft die Werte aller ARB-Dateien
- [x] Die englischen Texte folgen den Regeln aus CLAUDE.md sinngemäß (freundlich, kurz, ermutigend, keine Heil- oder Wirkversprechen)
- [x] Doku: HANDOFF, Abschnitt „Sprachen“, und Ticket 15 nennen Englisch als vorhanden; „Neue Sprache hinzufügen“ ist an Englisch erprobt

## Hinweise

- Der Tab „Haushalt“ heißt auf Englisch „Household“, weil „Home“ dort meist die Startseite meint; der eingebaute Bereich heißt „Home“.
- „Stups“ bleibt auch auf Englisch der Name der App und des Begleiters.
- Der Claim „Rein ins Tun.“ steht noch in keiner Oberfläche und deshalb nicht in den Sprachdateien. Seine englische Fassung wird festgelegt, wenn er eingebaut wird (siehe Ticket 05).
- Die Begriffe „Stupser“ und „Taten“ stehen noch nicht in den Sprachdateien; die englischen Begriffe legen die Tickets fest, die sie einführen.
- Der Wortlaut der englischen Texte wird im Review geprüft; Tests prüfen ihn nicht.
- Tests laufen mit der Systemsprache Englisch; Tests, die deutsche Texte erwarten, setzen `de` ausdrücklich.

## Umsetzungsstand

Testgetrieben in fünf Seams, benannt nach ihren Testdateien: `arb_parity_test.dart` (gleiche Schlüssel und Platzhalter in allen Sprachdateien; Platzhalter werden aus dem Text gelesen, Metadaten und Beschreibungen stehen nur in der Vorlage), `app_languages_test.dart` (die App folgt der Systemsprache, mit echten Texten als Literalen, und der Rückfall ist Englisch), `locale_resolution_test.dart` (Sprachwahl und Rückfall), `area_display_name_test.dart` (englische Bereichsnamen) und `no_hardcoded_texts_test.dart` (Wächter gegen feste Texte über alle Sprachen). Rot war zuerst nur der Rückfall und der Paritätstest; die Mechanik aus Ticket 15 trug den Rest. Gegenproben: ein fehlender Platzhalter im englischen Text und ein fester Text im Code schlagen an.

Nicht getestet: der Wortlaut der englischen Texte (Review).
