/// Priorität nach Safren: A wichtig, B mittel, C kann warten.
enum Priority { a, b, c }

/// Stand eines konkreten Tages einer Aufgabe.
enum OccurrenceStatus { open, started, done, postponed, skipped }

/// Energie am Morgen: bestimmt, wie viele Aufgaben „Heute“ vorschlägt.
enum Energy { low, medium, high }
