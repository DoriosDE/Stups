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

## Designregeln aus den Prototyp-Runden

- Ein Dashboard mit vielen Elementen (Energie-Chips, große Schritt-Karte, Figur, dicke Knöpfe) wirkte unübersichtlich.
- Eine Ansicht mit allen Aufgaben eines Raums untereinander wirkte überladen, weil mehrere Aufgaben gleichzeitig sichtbar waren.
- Bevorzugt: eine Karte für heute (erst die Energie-Frage, danach nur der nächste Schritt), ein kompakter Wochenplan darunter, in der Raumansicht immer nur eine Aufgabe mit Blättern, 5 Tabs.
- Gewünscht ist ein ansprechendes, verspieltes Design, das Spaß macht, aber nicht überlädt.
- Abgeleitete Regel: **Eine Sache pro Bildschirm.** Der nächste Schritt groß, alles andere eingeklappt oder zurückhaltend.

## Hinweise

- **Quellen ungeprüft:** Alle Literaturangaben stammen aus dem Gedächtnis und stehen in RESEARCH.md zur Prüfung. Das Ticket 00 behandelt das.
- **Prototyp-Datei** (`*.dc.html`) braucht die Laufzeit des Claude-Design-Canvas und läuft nicht direkt im Browser. Sie dient als Referenz für Screens, Texte, Farben und Logik.
