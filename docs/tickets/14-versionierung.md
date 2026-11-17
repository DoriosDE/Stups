# Ticket 14: Versionierung aus dem Tag

- **Status:** in Arbeit
- **Branch:** `feature/versionierung`
- **Designprinzip:** Verteilung (Ziel: Open Source, reproduzierbar)

## Ziel

Die App-Version kommt allein aus dem Git-Tag. Ein Tag `v0.x.y-dev` auf `develop` erzeugt eine Entwicklungs-App, die neben der echten App installiert sein kann, ein Tag `v0.x.y` auf `master` die Release-App.

## Akzeptanzkriterien

- [x] Tag-Format `v<Major>.<Minor>.<Patch>` mit optionalem `-dev`; alles andere bricht den Build ab
- [x] `versionName` ist der Tag ohne `v` (zum Beispiel `0.1.0-dev`)
- [x] `versionCode` ist `Major·1.000.000 + Minor·1.000 + Patch`, ohne Zusatz; Minor und Patch über 999 brechen ab
- [x] Die Berechnung ist eine kleine reine Funktion unter `tool/`, testgetrieben: Tag rein, Name, Code und Flavor raus
- [x] Zwei Flavors: `prod` (`de.dorios.stups`, App-Name „Stups“) und `dev` (`de.dorios.stups.dev`, App-Name „Stups Dev“), mit getrennten Daten
- [ ] Die CI wählt den Flavor anhand des Tags und baut eine Universal-APK (ohne `--split-per-abi`) (Workflow geschrieben, noch nicht auf GitHub gelaufen)
- [ ] Die CI prüft nach dem Build, dass `versionName` und `versionCode` der APK zu den erwarteten Werten passen (Skript lokal geprüft, in der CI noch nicht gelaufen)
- [x] Lokale Builds ohne Tag: `0.0.0-lokal`, Code 1, Flavor `dev`, damit Tests auf dem Gerät die echte App nicht überschreiben; `flutter run` und `flutter build` nehmen lokal standardmäßig `dev`
- [x] Eine eingecheckte `.vscode/launch.json` startet mit `--flavor dev` (Ausnahmeregel in der `.gitignore`)
- [x] `pubspec.yaml`: `version: 0.0.0-lokal+1` mit Kommentar, dass die echte Version vom Tag kommt (so zeigen lokale Builds dieselbe Version wie `versionFromTag(null)`)
- [x] Unter „Mehr“ steht die Version (`package_info_plus`), mit Widget-Test
- [x] Doku: Versionsschema und Release-Ablauf in HANDOFF.md, Hinweis in CLAUDE.md

## Hinweise

- Ticket 10 (Release-APK) baut darauf auf und setzt dieses Ticket voraus.
- Flutter addiert bei `--split-per-abi` `1000 × ABI` zum Code (laut Template-Kommentar, noch nicht an einem Build geprüft). Die Universal-APK vermeidet das.
- Bei F-Droid muss die Build-Anleitung dieselben Werte aus dem Tag übergeben. Ob das dort sauber geht, ist noch zu prüfen.
- Die Dev-App hat eine eigene App-ID. Dadurch entsteht keine Kollision gleicher Codes zwischen Dev- und Release-Builds.

## Umsetzungsstand

Lokal geprüft: Beide Flavors bauen, `tool/verify_apk_version.sh` bestätigt App-ID, Name, `versionName` und `versionCode` (`0.1.0-dev`/1000 als Dev, `0.1.0`/1000 als Prod, `0.0.0-lokal`/1 ohne Tag und ohne Flavor). Auf einem Android-17-Gerät läuft die Dev-App neben einer älteren Stups-App, und unter „Mehr“ steht die Version. Offen bis zum Abschluss: erster grüner CI-Lauf, auch mit einem echten Tag (zum Beispiel `v0.0.1-dev`).

Nach dem Review ergänzt (Seam 3): `print_version.dart` ruft die testbare Funktion `run(args, out, err)` auf; Ausgabeformat, leerer Tag und Exit-Code 64 sind getestet. Die Erwartung für App-ID und App-Name kommt jetzt aus Dart (`BuildVersion.appId` und `label`) statt aus einer Shell-Kette in der CI.
