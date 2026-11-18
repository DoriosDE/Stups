# Ticket 04: Aufgaben

- **Status:** erledigt
- **Branch:** `feature/aufgaben`
- **Designprinzip:** Klein anfangen

## Ziel

Aufgaben lassen sich anlegen, ansehen und bearbeiten, mit erstem Mini-Schritt.

## Akzeptanzkriterien

- [x] Felder: Titel, erster Mini-Schritt, Unterschritte, geschätzte Dauer, Priorität A, B, C, Bereich, optional Fälligkeit und Erinnerung
- [x] Beim Anlegen fragt die App „Was ist der allererste Mini-Schritt?“ (ohne Vorschlag, siehe Hinweise)
- [x] Aufgabenliste nach Bereich, Detailansicht
- [x] Erledigen speichert die tatsächliche Dauer und zeigt den Vergleich ohne Bewertung
- [x] ~~Vorlagen für Mini-Schritte als JSON-Asset~~ entfällt (siehe Hinweise)

## Hinweise

- **Keine Vorschläge für den Mini-Schritt.** Ursprünglich sollte ein Vorschlag aus Vorlagen (JSON-Asset) vorausgefüllt sein. Das entfällt auf Wunsch des Maintainers: Das Feld bleibt leer und trägt nur die Frage. Dadurch gibt es keine Vorlagen-Datei und keinen Test dazu. SPEC ist entsprechend angepasst; RESEARCH.md nennt den Vorschlag noch als Idee (dort Evidenz, keine Anforderung).
- **Dauer wird abgefragt.** Beim Erledigen fragt ein Blatt „Wie viele Minuten hast du gebraucht?“, vorbelegt mit der Schätzung, ohne „Überspringen“. Der Fokusmodus (Ticket 06) kann später die gemessene Zeit dort vorbelegen. Das Vorkommen (`Occurrence`) für heute entsteht erst beim Erledigen; zweimal am selben Tag erledigt überschreibt die Dauer.
- **Vergleich ohne Bewertung:** „Geschätzt 10 Min., gebraucht 14 Min.“; gab es keine Schätzung, steht nur „Gebraucht: 14 Min.“.
- **Aufbau:** Formular und Detailansicht sind eigene Bildschirme über dem Rahmen mit Tabs (eine Sache pro Bildschirm, der Plus-Button „Kopf frei machen“ verdeckt dort nichts). Im Formular stehen oben nur Titel und erster Mini-Schritt; Dauer, Priorität, Bereich, weitere Schritte, Fälligkeit und Erinnerung liegen unter „Mehr Details“.
- **Standards:** Priorität B, Bereich „Persönliches“ (wie bei „Zur Aufgabe“ aus der Inbox, Ticket 03).
- **Liste:** Offene Aufgaben zuerst, darin A vor B vor C, dann die ältere zuerst; erledigte stehen durchgestrichen am Ende. Die Umschaltung „Inbox / Alle Aufgaben“ im Tab „Aufgaben“ kommt aus dem Prototyp, geöffnet wird die Inbox.
- **Bearbeiten und Schritte:** Die Unterschritte werden nach Position abgeglichen: Die ersten behalten ihre Zeile und damit ihre Haken (`SubtaskCheck`), neue kommen hinten dazu, überzählige fallen mit ihren Haken weg. Leert man mitten in der Liste den Text eines Schritts, fällt er weg, die späteren rücken nach und die Haken bleiben an der Position. Solange das Formular Schritte nur anhängen und umschreiben lässt, ist das genau; sobald Heute und Fokusmodus Haken speichern (Tickets 05 und 06) oder Schritte sich löschen und umsortieren lassen, sollte ein Schritt seine ID im Formular mitführen.
- **Schätzung 0:** Eine Schätzung von 0 Minuten gilt als keine Schätzung (die Datenlogik speichert dann nichts).
- **Alte Daten im Dialog:** Liegt ein gespeichertes Fälligkeitsdatum oder eine Erinnerung in der Vergangenheit, bietet der Datumsdialog diesen Tag mit an, statt abzubrechen.
- **Erledigt gilt einmalig:** In v0.1 gibt es genau ein Vorkommen je Aufgabe, „erledigt“ heißt: es gibt ein Vorkommen mit Status `done`. Eine Aufgabe lässt sich nicht an einem zweiten Tag erneut erledigen; Wiederholungen kommen mit Routinen (v0.2).
- **Erinnerung:** Gespeichert wird nur der Zeitpunkt (`reminderAt`); geplant wird er mit Ticket 07.
- **Bewusst nicht dabei:** Schritte abhaken (kommt mit „Heute“ und dem Fokusmodus, weil dafür ein gestartetes Vorkommen nötig ist), eigene Bereiche anlegen, ausblenden oder umbenennen, Aufgaben löschen oder deaktivieren, Wochenansicht.

## Umsetzungsstand

Testgetrieben an vier Seams, vorab abgestimmt (der fünfte, die Vorlagen, entfiel mit der Entscheidung oben): `task_repository_test.dart` (Datenlogik mit In-Memory-Datenbank: Anlegen mit allen Feldern und Schritten, Bereinigen der Eingaben, leerer Titel, Bearbeiten, Liste mit Filter und Reihenfolge, Erledigen, Bereiche), `task_form_test.dart` (Formular: Pflichtfeld, eingeklappte Details, Dauer, Priorität, Bereich, weitere Schritte, Fälligkeit, Erinnerung), `task_list_test.dart` (Umschalter, Zeilen, Bereichs-Chips, erledigte Aufgaben, leere Liste) und `task_detail_test.dart` (Detailansicht, Erledigen mit Vergleich, Bearbeiten). Dazu prüft `localized_texts_test.dart`, dass alle neuen Texte aus den Sprachdateien kommen.

Gegenproben: Eine fehlende Prüfung auf 0 Minuten und ein fester Text statt `l10n.taskFirstStepHeading` lassen die zugehörigen Tests anschlagen. Die Tests zu Reihenfolge, Filter und Speichern waren vor der Umsetzung rot.

Nachbesserung nach dem Review (je mit rotem Test zuerst): alte Daten im Datumsdialog (zwei Tests im Formular, die Dialoge brachen mit einer Assertion ab), Schätzung 0 (Datenlogik) und Schritte mit Haken beim Bearbeiten (zwei Tests in der Datenlogik, die Schritte bekamen vorher neue IDs und verloren ihre Haken).

Nicht getestet: der Wortlaut der Texte (Review), das Aussehen und die Bedienung mit der echten Tastatur auf dem Gerät. Bei gleicher Priorität und gleicher Sekunde der Anlage ist die Reihenfolge der Liste nicht festgelegt (drift speichert Zeitpunkte in ganzen Sekunden).
