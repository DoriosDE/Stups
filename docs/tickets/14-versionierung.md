# Ticket 14: Versionierung aus dem Tag

- **Status:** offen
- **Branch:** `feature/versionierung`
- **Designprinzip:** Verteilung (Ziel: Open Source, reproduzierbar)

## Ziel

Die App-Version kommt allein aus dem Git-Tag. Ein Tag `v0.x.y-dev` auf `develop` erzeugt eine Entwicklungs-App, die neben der echten App installiert sein kann, ein Tag `v0.x.y` auf `master` die Release-App.

## Akzeptanzkriterien

- [ ] Tag-Format `v<Major>.<Minor>.<Patch>` mit optionalem `-dev`; alles andere bricht den Build ab
- [ ] `versionName` ist der Tag ohne `v` (zum Beispiel `0.1.0-dev`)
- [ ] `versionCode` ist `Major·1.000.000 + Minor·1.000 + Patch`, ohne Zusatz; Minor und Patch über 999 brechen ab
- [ ] Die Berechnung ist eine kleine reine Funktion unter `tool/`, testgetrieben: Tag rein, Name, Code und Flavor raus
- [ ] Zwei Flavors: `prod` (`de.dorios.stups`, App-Name „Stups“) und `dev` (`de.dorios.stups.dev`, App-Name „Stups Dev“), mit getrennten Daten
- [ ] Die CI wählt den Flavor anhand des Tags und baut eine Universal-APK (ohne `--split-per-abi`)
- [ ] Die CI prüft nach dem Build, dass `versionName` und `versionCode` der APK zu den erwarteten Werten passen
- [ ] Lokale Builds ohne Tag: `0.0.0-lokal`, Code 1, Flavor `dev`, damit Tests auf dem Gerät die echte App nicht überschreiben; `flutter run` und `flutter build` nehmen lokal standardmäßig `dev`
- [ ] Eine eingecheckte `.vscode/launch.json` startet mit `--flavor dev` (Ausnahmeregel in der `.gitignore`)
- [ ] `pubspec.yaml`: `version: 0.0.0+1` mit Kommentar, dass die echte Version vom Tag kommt
- [ ] Unter „Mehr“ steht die Version (`package_info_plus`), mit Widget-Test
- [ ] Doku: Versionsschema und Release-Ablauf in HANDOFF.md, Hinweis in CLAUDE.md

## Hinweise

- Ticket 10 (Release-APK) baut darauf auf und setzt dieses Ticket voraus.
- Flutter addiert bei `--split-per-abi` `1000 × ABI` zum Code (laut Template-Kommentar, noch nicht an einem Build geprüft). Die Universal-APK vermeidet das.
- Bei F-Droid muss die Build-Anleitung dieselben Werte aus dem Tag übergeben. Ob das dort sauber geht, ist noch zu prüfen.
- Die Dev-App hat eine eigene App-ID. Dadurch entsteht keine Kollision gleicher Codes zwischen Dev- und Release-Builds.
