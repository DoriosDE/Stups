# Klickbarer Prototyp

`04-organisations-app.dc.html` zeigt die ganze App: Heute, Aufgaben (Inbox, Liste, Detail), Routinen (Ablauf und Gewohnheiten), Haushalt, Mehr (Wochenrückblick), den Plus-Button „Kopf frei machen“ und den Fokusmodus mit Ablenkungs-Parkplatz. `canvas.json` ist der Index des Canvas (Position, Titel, Hinweisnotiz).

## Wichtig zur Laufzeit

Die `.dc.html`-Datei ist für die Laufzeit des Claude-Design-Canvas geschrieben (sie lädt `./support.js`, das hier nicht enthalten ist). Im Browser direkt geöffnet, funktioniert sie **nicht**. Nutze sie als Referenz:

- **Markup** (zwischen `<x-dc>` und `</x-dc>`): Screens, Layout, Abstände, Farben, Texte. `{{ … }}` sind Platzhalter für Werte aus der Logik, `<sc-if>` und `<sc-for>` sind Bedingungen und Schleifen.
- **Logik** (`<script type="text/x-dc">`): Beispieldaten (Aufgaben, Routinen, Räume, Gewohnheiten), Zustandsautomat der App (`this.state`) und alle Abläufe, etwa Tagesplan aus Energie, Abhaken, Timer, Feier, Wochenrückblick. Das lässt sich gut als Vorlage für Riverpod-Provider und Widgets lesen.
- **Tweaks** (`data-props`): Akzentfarbe, Animationen, Begleiter-Figur ein/aus. Die Figur ist das Staubwölkchen, der Begleiter von Stups. Ihr Name ist frei wählbar, Standard ist „Stups“.

## Design-Tokens

| Token | Wert |
| --- | --- |
| Hintergrund | #F6F4FF |
| Text | #1F1A3D |
| Hauptfarbe | #5B3DF5 (dunkle Kante #3B289F, Tint #EBE8FE) |
| Start-Momente | #FFC93C (Kante #D9A514) |
| Erledigt | #19C39C |
| Wochentage | Mo #FFE3DE, Di #DDF7EE, Mi #E6E0FF, Do #FFF1CC, Fr #DCEEFF, Sa #FFE0F0, So #ECEAF4 |
| Schriften | Fredoka (Überschriften), Lexend (Text) |
| Radien | Karten 20–28 px, Buttons 14–18 px |
