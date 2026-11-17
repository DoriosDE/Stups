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

## Designregeln aus den Prototyp-Runden

- Ein Dashboard mit vielen Elementen (Energie-Chips, große Schritt-Karte, Figur, dicke Knöpfe) wirkte unübersichtlich.
- Eine Ansicht mit allen Aufgaben eines Raums untereinander wirkte überladen, weil mehrere Aufgaben gleichzeitig sichtbar waren.
- Bevorzugt: eine Karte für heute (erst die Energie-Frage, danach nur der nächste Schritt), ein kompakter Wochenplan darunter, in der Raumansicht immer nur eine Aufgabe mit Blättern, 5 Tabs.
- Gewünscht ist ein ansprechendes, verspieltes Design, das Spaß macht, aber nicht überlädt.
- Abgeleitete Regel: **Eine Sache pro Bildschirm.** Der nächste Schritt groß, alles andere eingeklappt oder zurückhaltend.

## Hinweise

- **Quellen ungeprüft:** Alle Literaturangaben stammen aus dem Gedächtnis und stehen in RESEARCH.md zur Prüfung. Das Ticket 00 behandelt das.
- **Prototyp-Datei** (`*.dc.html`) braucht die Laufzeit des Claude-Design-Canvas und läuft nicht direkt im Browser. Sie dient als Referenz für Screens, Texte, Farben und Logik.
