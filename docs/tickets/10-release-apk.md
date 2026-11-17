# Ticket 10: Release-APK

- **Status:** offen
- **Branch:** `feature/release-apk`
- **Designprinzip:** Verteilung (Ziel: Open Source, kostenlos)

## Ziel

Ein Tag `v*` auf `master` erzeugt eine signierte APK als GitHub Release.

## Akzeptanzkriterien

- [ ] Launcher-Icon: gelber Punkt mit zwei Wellenringen auf Violett (#5B3DF5), adaptiv mit einfarbiger Variante
- [ ] GitHub Actions baut bei Tag `v*` eine signierte Release-APK mit der Version aus dem Tag (siehe Ticket 14) und hängt sie an ein GitHub Release
- [ ] Keystore und Passwörter liegen als GitHub-Secrets; Schritt-für-Schritt-Anleitung zum Erzeugen
- [ ] Die Release-APK geht zunächst nur an den Testkreis (siehe Ticket 11)

## Hinweis

Den Keystore erzeugt und sichert der Maintainer; ein Verlust ist nicht reparierbar.

Setzt Ticket 14 (Versionierung aus dem Tag) voraus.
