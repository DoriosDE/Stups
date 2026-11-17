# Projekt: Stups – Rein ins Tun.

Quelloffene Flutter-App (zunächst Android), die Erwachsenen mit ADHS beim Organisieren hilft. Frühe Entwicklung, v0.1 in Arbeit.

**Begriffe in der UI:** App „Stups“, Claim „Rein ins Tun.“, Erinnerungen = „Stupser“, Schnellerfassung = „Kopf frei machen“, Belohnungszähler = „Taten“, Begleiter (Maskottchen) = frei benennbar, Standardname „Stups“; Texte nutzen den gewählten Namen.

## Quellen der Wahrheit

- `docs/SPEC.md`: Anforderungen, Architektur, Datenmodell, Roadmap. Lies die betroffenen Abschnitte vor jeder Feature-Arbeit.
- `docs/HANDOFF.md`: Entscheidungsverlauf und Nutzerfeedback zum UI. Lies es bei Fragen zu Ablauf, Layout oder Plattform.
- `docs/RESEARCH.md`: Evidenz hinter den Designprinzipien. Lies es, wenn ein neues Feature begründet werden muss.
- `prototypes/04-organisations-app.dc.html`: Referenz für Screens, Texte, Farben; Daten und Logik stehen im `<script>`-Block.

## Arbeitsregeln

- Jedes Feature lässt sich auf ein Designprinzip aus der Tabelle „Designprinzipien“ in SPEC.md zurückführen; nenne es im PR.
- **Eine Sache pro Bildschirm:** der nächste Schritt groß, eine Aufgabe zur Zeit, alles andere eingeklappt.
- UI-Texte auf Deutsch, Du-Form, kurz und ermutigend; Rückschläge werden mit Neustart beantwortet, nie mit Vorwürfen oder verlierbaren Serien.
- Offline-first mit drift (SQLite), ohne Tracker und ohne proprietäre Dienste, damit F-Droid möglich bleibt.
- Erinnerungen laufen über die Schnittstelle `ReminderService`; die Web-Implementierung ist ein No-op.
- Texte beschreiben Unterstützung im Alltag; Heil- oder Wirkversprechen bleiben draußen (Medizinprodukte-Recht).
- Namen, Texte und Grafiken sind eigen; fremdes Material wird nicht übernommen.
- Riverpod ohne Codegenerierung; Code ist feature-first gegliedert (`lib/core/`, `lib/features/<feature>/`).
- Aufgaben stehen als Tickets in `docs/tickets/` (eine Datei pro Ticket). Jedes Ticket nennt das zugrunde liegende Designprinzip.
- Branches: Arbeit in `feature/<thema>` von `develop`, Merge mit `--no-ff` nur auf Wunsch. Commit-Nachrichten deutsch, kurz, im Infinitiv, mit Ticket-Verweis am Ende, ohne `Co-Authored-By`-Zeile.
