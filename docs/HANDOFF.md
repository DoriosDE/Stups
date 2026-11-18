# Projektverlauf und Entscheidungen

Stand: 17. November 2026. Dieses Dokument fasst zusammen, wie das Konzept entstanden ist und welche Entscheidungen gelten. Inhalte, die in anderen Dateien stehen, sind nur verlinkt.

## Wo was steht

| Thema | Datei |
| --- | --- |
| Anforderungen, Architektur, Datenmodell, Roadmap, offene Fragen | [SPEC.md](SPEC.md) |
| Wissenschaftliche Herleitung und Quellen-Prüfliste | [RESEARCH.md](RESEARCH.md) |
| Aufgaben (ein Ticket pro Datei) | [tickets/](tickets/) |
| Klickbarer Prototyp | [../prototypes/README.md](../prototypes/README.md) |

## Verlauf

1. **Ausgangspunkt:** Ein Haushalts-Konzept für Menschen mit ADHS, mit Raumtagen, kurzen Runden, Vorrat und Einkauf.
2. **Plattform:** Verglichen wurden eine Web-App auf GitHub Pages, ein selbst gehosteter Docker-Dienst und eine native Flutter-App. Erinnerungen bei geschlossener App sind unverzichtbar. Web Push braucht einen Server und läuft auf iPhones nur als Home-Bildschirm-App, ein Docker-Dienst taugt für den Eigengebrauch, nicht für die Zielgruppe. Entscheidung: **Flutter, Open Source, Android zuerst.** Auch eine PWA als Testversion wurde erwogen und verworfen: keine Erinnerungen bei geschlossener App, Safari kann Daten nach einigen Tagen ohne Nutzung löschen, Flutter Web lädt mehrere MB. Der `ReminderService` bekommt trotzdem eine Schnittstelle mit Web-No-op, damit ein Web-Build später möglich bleibt.
3. **Neuausrichtung:** Statt einer reinen Haushalts-App entsteht eine ganzheitliche Organisations-App für ADHS, die auf wissenschaftlichen Grundlagen aufbaut (siehe RESEARCH.md).
4. **Umfang Version 1:** Aufgaben und Tagesplanung, Routinen und Gewohnheiten, Haushalt. Termine, Finanzen und Gesundheit kommen später.
5. **Name:** App **Stups**, Claim **„Rein ins Tun.“** Erinnerungen heißen „Stupser“, die Schnellerfassung „Kopf frei machen“, erledigte Dinge zählen als **„Taten“**. Der Begleiter ist frei benennbar, Standardname „Stups“.
    - Begründung: kurz, eigenständig, vermutlich schützbar; „Tun“ benennt die Kernhürde bei ADHS (Barkley: Problem des Tuns, nicht des Wissens).
    - Verworfen: „Kopffrei“ (beschreibend, schwer schützbar), „Kopfstups“ (lang, international schwierig), „Ins Tun“, „Tunlich“; als Begleiter-Namen Funke, Flitz, Hops, Mo, Wuschel, Fussel und Tier-Namen; als Belohnungsbegriff Funken, Schritte, Geschafft, Erledigt, Haken.
6. **Begleiter:** Das Staubwölkchen aus dem Prototyp (siehe SPEC, Abschnitt Design).

## Entscheidungen für v0.1

| Thema | Entscheidung |
| --- | --- |
| Plattform | Native Flutter-App für Android, kein Web |
| Lizenz | Apache-2.0 |
| Android | ab Android 8 (API 26); iOS und Apple-Account vertagt |
| App-ID | `de.dorios.stups`, Projekt in der Repo-Wurzel |
| Code-Struktur | Feature-first (`lib/core/`, `lib/features/`) |
| State-Management | Riverpod ohne Codegenerierung |
| IDs und Zeit | UUIDs als Text, UTC-Zeitpunkte, lokale Kalendertage als `yyyy-MM-dd` |
| Schema | Wiederholungen und Occurrence von Anfang an, Engine erst ab v0.2 |
| Sprachen | Texte in ARB-Dateien, Deutsch und Englisch (Ticket 16); Systemsprache; Rückfall Englisch; erzeugter Sprachcode nicht im Git |
| Datenbank | sprachneutral: eingebaute Bereiche nur als Kennung (`household`, `work`, `personal`), Namen aus Sprachdateien (Ticket 15); eingebaute Bereiche nur ein- und ausblendbar |
| Generierter Code | `*.g.dart` (drift) nicht im Git; `dart run build_runner build` lokal und in der CI |
| Tests | Logik testgetrieben (Tagesplan, Erinnerungsfenster, Backup-Roundtrip), Widget-Tests für Heute und Fokus |
| Verpasste Aufgaben | verfallen aus dem Tagesplan, bleiben in der Liste, keine Überfällig-Liste |
| Tagesplan | A, dann B, dann C, nach Fälligkeit, höchstens 3 |
| Belohnung | Haptik, Konfetti, Taten-Zähler (berechnet) schon in v0.1 |
| Onboarding | in v0.1 drei Bildschirme |
| Fokus-Timer | gespeicherter Endzeitpunkt; exakter Alarm wird erst beim ersten Timer-Start erklärt und abgefragt |
| Launcher-Icon | gelber Punkt mit zwei Wellenringen auf Violett, vorläufig |
| Haushalt | pro Tag ein Raum als Standard, mehrere optional |

## Arbeitsweise

- **Branches:** `develop` und `master`. Arbeit läuft in `feature/<thema>` von `develop`, gemergt wird mit `--no-ff`, und zwar erst auf Wunsch. Releases entstehen auf `master`. Auf `develop` heißen Tags `v0.x.y-dev`, auf `master` `v0.x.y`.
- **Commits:** deutsch, kurz, im Infinitiv, mit Ticket-Verweis am Ende, zum Beispiel `Drift-Schema für Aufgaben anlegen (#02)`.
- **Tickets:** eine Markdown-Datei pro Ticket in [tickets/](tickets/), mit Ziel, Akzeptanzkriterien, Designprinzip, Branch und Status.
- **Release:** Ein Tag `v*` auf `master` löst in GitHub Actions einen signierten Release-Build aus und hängt die APK an ein GitHub Release. Den Keystore erzeugt und sichert der Maintainer.
- **Voraussetzungen vor dem ersten öffentlichen Release:** Namensprüfung (DPMA, TMview Klassen 9 und 42, Stores, Domain, GitHub), Logo, geprüfte Quellen. Bis dahin geht die APK nur an einen kleinen Testkreis.
- **Vor v1.0:** fachliche Begleitung und rechtliche Prüfung der Abgrenzung zum Medizinprodukt.

## Versionierung und Varianten

Die Version kommt allein aus dem Git-Tag. `tool/print_version.dart` berechnet daraus Name, Code, Variante, App-ID und App-Name. Die Werte für App-ID und App-Name stehen bewusst zweimal im Projekt: in `tool/version_from_tag.dart` (die Erwartung, getestet) und in `android/app/build.gradle.kts` (was wirklich in die APK kommt). Die CI vergleicht beide an der gebauten APK, so fällt jede Abweichung auf.

| Tag | Branch | versionName | versionCode | Variante | App-ID | App-Name |
| --- | --- | --- | --- | --- | --- | --- |
| `v0.1.0-dev` | `develop` | `0.1.0-dev` | 1000 | `dev` | `de.dorios.stups.dev` | Stups Dev |
| `v0.1.0` | `master` | `0.1.0` | 1000 | `prod` | `de.dorios.stups` | Stups |
| kein Tag (lokal) | beliebig | `0.0.0-lokal` | 1 | `dev` | `de.dorios.stups.dev` | Stups Dev |

- **versionCode:** `Major·1.000.000 + Minor·1.000 + Patch`, ohne Zusatz. Minor und Patch gehen bis 999, Major bis 2099 (Android erlaubt höchstens 2.100.000.000).
- **Tag-Format:** `v<Major>.<Minor>.<Patch>` mit optionalem `-dev`, ohne führende Nullen. Alles andere bricht den Build ab.
- **Dev und Prod nebeneinander:** Die Dev-App hat eine eigene App-ID und eigene Daten. Deshalb ist es unkritisch, dass Dev- und Release-Tag denselben Code haben können.
- **Universal-APK:** Wir bauen ohne `--split-per-abi`, weil Flutter dort laut Kommentar im Projekt-Template `1000 × ABI` zum Code addiert (an einem Split-Build noch nicht geprüft).
- **Lokal:** `flutter run` und `flutter build` nehmen ohne Angabe die Dev-App (`default-flavor` in der `pubspec.yaml`). In VS Code startet `.vscode/launch.json` mit `--flavor dev`.
- **CI:** Bei jedem Lauf bestimmt die CI die Version mit `tool/print_version.dart` (mit Tag `v*` aus dem Tag, sonst `0.0.0-lokal`), übergibt `--flavor`, `--build-name` und `--build-number` und prüft danach mit `tool/verify_apk_version.sh`, ob die APK zu den erwarteten Werten passt. Ein ungültiger Tag bricht den Lauf ab.
- **F-Droid:** Die Build-Anleitung dort muss dieselben Werte aus dem Tag übergeben. Das ist noch zu prüfen.

## Datenbank

Die Datenbank ist eine lokale SQLite-Datei, beschrieben mit drift (`lib/core/db/`: eine Datei pro Tabelle unter `tables/`, die Klasse `AppDatabase`). Sie ist sprachneutral: Texte, die die App mitbringt, stehen nicht in der Datenbank (eingebaute Bereiche tragen nur eine Kennung wie `household`, ihr Name kommt aus den Sprachdateien).

**Erzeugter Code liegt nicht im Git.** Nach dem Klonen und nach jeder Änderung an einer Tabelle:

```
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema generate drift_schemas/ test/generated/
```

Der erste Befehl erzeugt `*.g.dart`, der zweite den Test-Helfer für den Schema-Schnappschuss. Die CI führt beide aus.

**Schema ändern:**

1. `schemaVersion` in `AppDatabase` erhöhen und eine Migration in `migration` ergänzen.
2. Neuen Schnappschuss schreiben: `dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/`. Der alte Schnappschuss (`drift_schema_v1.json` und so weiter) bleibt im Git, er ist die Grundlage für Migrationstests. (Einmal, mit Ticket 04, wurde `drift_schema_v1.json` überschrieben und `schemaVersion` blieb 1, weil die App unveröffentlicht war. Ab der ersten Veröffentlichung gilt der Ablauf hier ohne Ausnahme.)
3. Test-Helfer neu erzeugen (zweiter Befehl oben) und die Migration testen.

Der Test `test/core/db/schema_snapshot_test.dart` schlägt fehl, wenn das Schema im Code vom Schnappschuss abweicht. Ändert man also eine Tabelle und vergisst Version oder Schnappschuss, fällt das sofort auf. Er vergleicht immer mit dem Schnappschuss der aktuellen `schemaVersion`, braucht also nach Schritt 1 und 2 keine Anpassung.

**Zu wissen:**
- `CHECK`-Regeln in `customConstraints` müssen als **Text-Literale** in der Tabelle stehen, nicht über eine Hilfsfunktion. Der Schnappschuss-Generator liest nur Literale; eine Regel, die er nicht sieht, fehlt im Schnappschuss.
- Eine Spalte `text` heißt in Dart `content` (`text().named('text')`), weil `text` in drift die Methode zum Anlegen von Spalten ist.
- Zeitpunkte werden als absolute Zeit (UTC) gespeichert, Kalendertage als lokaler Text `yyyy-MM-dd`; das Format erzwingt eine `CHECK`-Regel.
- **Widget-Tests mit drift-Streams hängen beim Schließen.** Zeigt ein Bildschirm eine Datenbank-Abfrage als Stream (`StreamProvider`), hängt `db.close()` im `tearDown` für immer. Die Datenbank erst im `addTearDown` des Tests schließen: erst `pumpWidget(const SizedBox())`, dann `pump(Duration(seconds: 1))` (die Fake-Zeit arbeitet die Timer der Abmeldung ab), dann `await tester.runAsync(db.close)`. Direkte Datenbankzugriffe im Test (Daten vorbereiten, Ergebnis nachprüfen) laufen in `tester.runAsync`; was die Oberfläche auslöst, läuft mit `pumpAndSettle`. Beispiel: `test/features/inbox/inbox_view_test.dart`. Für neue Widget-Tests gibt es `pumpStupsApp` in `test/support/app_harness.dart`: Es startet die App mit In-Memory-Datenbank, legt auf Wunsch vorher Daten an (`seed`) und schließt die Datenbank richtig.
- **Kein `stream.first` im Handler.** Wer in einem Tipp-Handler einen drift-Stream mit `.first` ausliest, sieht im Widget-Test nach `pumpAndSettle` kein Ergebnis; erst eine echte Wartezeit (`runAsync` mit `Future.delayed`) ließ den Speichervorgang durchlaufen. Besser den Wert aus einem Provider lesen, den die Oberfläche ohnehin beobachtet (Beispiel: `areasProvider` im Aufgabenformular).
- Fremdschlüssel sind eingeschaltet. Löschen einer Aufgabe entfernt Unterschritte, Vorkommen und Häkchen; ein Bereich mit Aufgaben lässt sich nicht löschen. Dass eingebaute Bereiche nie gelöscht werden dürfen, setzt erst die Aufgabenlogik (Ticket 04) durch, nicht das Schema.

## Sprachen

Alle Oberflächentexte stehen in Sprachdateien (ARB) unter `lib/l10n/`. Deutsch (`app_de.arb`) ist die Vorlage, Englisch (`app_en.arb`) ist die zweite Sprache.

**Text verwenden:** In einem Widget `context.l10n.tabToday` (aus `lib/core/l10n/l10n.dart`). Fest eingetragene Texte gibt es nicht; der Test `test/core/l10n/no_hardcoded_texts_test.dart` schlägt an, wenn ein Text aus der Sprachdatei zusätzlich als Literal im Code steht.

**Neuen Text anlegen:**

1. Schlüssel in `lib/l10n/app_de.arb` ergänzen: camelCase mit Präfix (`tab…`, `area…`, `<feature>Hint`), dazu `@schlüssel` mit `description` für Übersetzer. Platzhalter als `{name}` mit `placeholders`.
2. `flutter pub get` erzeugt den Code neu (`lib/l10n/app_localizations*.dart`).
3. Im Code über `context.l10n.<schlüssel>` verwenden.

**Neue Sprache hinzufügen:** `lib/l10n/app_<code>.arb` mit genau den Schlüsseln der Vorlage anlegen (so wie `app_en.arb`): nur `@@locale` und die Texte, ohne `description`; Beschreibungen und Platzhalter-Metadaten stehen nur in der Vorlage. Platzhalter wie `{version}` stehen im Text selbst. `flutter pub get` erzeugt den Code. Der Test `test/core/l10n/arb_parity_test.dart` prüft Schlüssel und Platzhalter jeder weiteren Sprache gegen die Vorlage, der Wächter gegen feste Texte prüft alle Sprachen. Der Rückfall gilt, wenn keine Systemsprache unterstützt wird; er ist Englisch (`fallbackLocale` in `lib/core/l10n/locale_resolution.dart`).

**Erzeugter Sprachcode liegt nicht im Git** (`lib/l10n/app_localizations*.dart`, ignoriert). Er entsteht bei `flutter pub get`, auch in der CI. Die CI prüft das Format deshalb vor `pub get`.

**Zu wissen:**
- Tests laufen mit der Systemsprache Englisch. Ein Test, der deutsche Texte erwartet, setzt `tester.platformDispatcher.localesTestValue = const [Locale('de')]` (siehe `test/widget_test.dart`) oder `locale: Locale('de')` an der `MaterialApp`.
- Die App folgt der Systemsprache. Eine eigene Sprachwahl in den Einstellungen gibt es noch nicht.
- Die Delegates stehen in `appLocalizationsDelegates` (`lib/core/l10n/l10n.dart`). Der erzeugte `AppLocalizations.localizationsDelegates` taugt nicht, weil er die veraltete `GlobalMaterialLocalizations` aus `flutter_localizations` nimmt und nicht die aus `material_ui`. Die dadurch erzeugte Meldung `deprecated_member_use` im erzeugten Code unterdrückt der `header` in `l10n.yaml`; die erzeugten Dateien bleiben sonst in der Analyse. Der `header` kann entfallen, sobald der Generator die Klassen aus `material_ui` nimmt.
- Anzeigenamen eingebauter Bereiche liefert `areaDisplayName(l10n, area)`; ein eigener Name in der Datenbank gewinnt.
- In Tests liefert `MarkerLocalizations` (`test/support/marker_localizations.dart`) statt der Texte Marker wie `⟦tabToday⟧`. So zeigt ein Test, dass ein Text aus den Sprachdateien kommt, unabhängig vom Wortlaut.

## Heute und Feier

- **Tagesplan:** `lib/features/today/plan_picker.dart` wählt die Aufgaben (reine Funktion, getestet), `day_plan_repository.dart` legt den Plan pro Kalendertag in `DayPlans` ab (`plannedTaskIds` als JSON). Ein neuer Tag hat keinen Plan; Unerledigtes verfällt dadurch von selbst.
- **Taten:** `TaskRepository.watchDeedCount()` zählt die erledigten Vorkommen; es gibt keine eigene Tabelle.
- **Einstellungen:** `lib/core/settings/` liest und schreibt die Tabelle `Settings` (Begleiter anzeigen und benennen, Vibrieren, Animationen reduzieren). Der Standardname des Begleiters steht in den Sprachdateien (`companionDefaultName`); in der Datenbank steht nur ein selbst vergebener Name.
- **Feier:** `celebrate()` in `lib/features/today/celebration.dart` läuft nach dem Erledigen in der Detailansicht. Konfetti und Begleiter-Animation entfallen bei „Animationen reduzieren“ und bei der Systemeinstellung „Bewegung reduzieren“. Das Vibrieren wird nicht abgewartet (im Widget-Test hängt ein `await` auf `HapticFeedback` ohne Plattform-Handler).
- **Tests:** Wer in einem Widget-Test eine Aufgabe erledigt, sieht danach die Feier und schließt sie mit „Hier bleiben“ oder „Zu Heute“.

## Fokusmodus

- **Sitzung:** `lib/features/focus/focus_session.dart` ist die reine Zeitlogik (Restzeit, Ende, Verlängern, Fortschritt, gebrauchte Minuten), `focus_repository.dart` speichert die eine laufende Sitzung als JSON in `Settings` (Schlüssel `focusSession`) und legt das Vorkommen von heute als `started` an. Beim Backup (Ticket 08) und beim Zurücksetzen ist dieser Schlüssel mitzudenken.
- **Countdown:** Der Endzeitpunkt ist die Wahrheit. Der Bildschirm zeichnet nur neu, wenn sich die angezeigte Sekunde ändert, und beim Zurückkehren aus dem Hintergrund (`AppLifecycleState.resumed`).
- **Uhr in Tests:** `clockProvider` (`lib/core/clock/clock_provider.dart`) lässt sich überschreiben; `pumpStupsApp(..., overrides: [...])` reicht das durch. `taskRepositoryProvider` und `focusRepositoryProvider` nutzen dieselbe Uhr. Beispiel: `test/features/focus/focus_flow_test.dart` (die Uhr springt, dann `pump(Duration(seconds: 1))` für den Tick).
- **Zurück-Knopf im Test:** `tester.pageBack()` findet ihn nicht; `find.byTooltip('Zurück')` tippen.

## Designregeln aus den Prototyp-Runden

- Ein Dashboard mit vielen Elementen (Energie-Chips, große Schritt-Karte, Figur, dicke Knöpfe) wirkte unübersichtlich.
- Eine Ansicht mit allen Aufgaben eines Raums untereinander wirkte überladen, weil mehrere Aufgaben gleichzeitig sichtbar waren.
- Bevorzugt: eine Karte für heute (erst die Energie-Frage, danach nur der nächste Schritt), ein kompakter Wochenplan darunter, in der Raumansicht immer nur eine Aufgabe mit Blättern, 5 Tabs.
- Gewünscht ist ein ansprechendes, verspieltes Design, das Spaß macht, aber nicht überlädt.
- Abgeleitete Regel: **Eine Sache pro Bildschirm.** Der nächste Schritt groß, alles andere eingeklappt oder zurückhaltend.

## Hinweise

- **Quellen ungeprüft:** Alle Literaturangaben stammen aus dem Gedächtnis und stehen in RESEARCH.md zur Prüfung. Das Ticket 00 behandelt das.
- **Prototyp-Datei** (`*.dc.html`) braucht die Laufzeit des Claude-Design-Canvas und läuft nicht direkt im Browser. Sie dient als Referenz für Screens, Texte, Farben und Logik.
