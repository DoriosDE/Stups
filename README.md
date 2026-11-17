# Stups – Rein ins Tun.

**Stups** ist eine quelloffene Organisations-App für Erwachsene mit ADHS, als Flutter-App zunächst für Android. Sie setzt gut untersuchte Strategien aus der ADHS-Forschung in den Alltag um: Dinge sichtbar machen, Aufgaben zerlegen, Zeit sichtbar machen und sofort belohnen. Version 1 umfasst Aufgaben und Tagesplanung, Routinen und Gewohnheiten sowie Haushalt.

## Projektstand

Frühe Entwicklung (v0.1 in Arbeit). Es gibt eine Spezifikation, eine Recherche-Grundlage und einen klickbaren Prototyp. Einstieg: **[docs/HANDOFF.md](docs/HANDOFF.md)**.

## Ordnerstruktur

```
stups/
├── README.md              ← diese Datei
├── CLAUDE.md              ← Kontext für Coding-Agenten (z. B. Claude Code)
├── LICENSE                ← Apache-2.0
├── docs/
│   ├── HANDOFF.md         ← Entscheidungen, Arbeitsweise, nächste Schritte
│   ├── SPEC.md            ← Spezifikation (Quelle der Wahrheit)
│   ├── RESEARCH.md        ← wissenschaftliche Grundlagen + Quellen-Prüfliste
│   └── tickets/           ← ein Ticket pro Datei
├── prototypes/            ← klickbarer Prototyp (Referenz für Screens und Logik)
├── lib/, android/, test/  ← Flutter-App
└── .github/workflows/     ← CI und Release
```

## Lizenz

[Apache-2.0](LICENSE)

## In VS Code

- Markdown-Vorschau: `Strg+Shift+V` (macOS: `Cmd+Shift+V`)
- Für das Architektur-Diagramm in SPEC.md eine Mermaid-Erweiterung installieren, z. B. „Markdown Preview Mermaid Support“
- Für Flutter: die offiziellen Erweiterungen „Flutter“ und „Dart“
