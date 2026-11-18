import 'dart:convert';

/// Eine laufende Fokus-Sitzung zu einer Aufgabe.
///
/// Der Countdown beruht auf dem gespeicherten Endzeitpunkt [endsAt]. Die
/// Restzeit wird bei jedem Blick aus der Uhr berechnet, nicht heruntergezählt;
/// so stimmt sie auch, wenn die App im Hintergrund war oder beendet wurde.
/// Alle Zeitpunkte sind UTC.
class FocusSession {
  const FocusSession({
    required this.taskId,
    required this.occurrenceId,
    required this.startedAt,
    required this.segmentStartedAt,
    required this.endsAt,
  });

  /// Beginnt eine Sitzung, die [length] dauert.
  factory FocusSession.start({
    required String taskId,
    required String occurrenceId,
    required DateTime now,
    required Duration length,
  }) {
    final utc = now.toUtc();
    return FocusSession(
      taskId: taskId,
      occurrenceId: occurrenceId,
      startedAt: utc,
      segmentStartedAt: utc,
      endsAt: utc.add(length),
    );
  }

  factory FocusSession.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    DateTime time(String key) => DateTime.parse(map[key] as String).toUtc();
    return FocusSession(
      taskId: map['taskId'] as String,
      occurrenceId: map['occurrenceId'] as String,
      startedAt: time('startedAt'),
      segmentStartedAt: time('segmentStartedAt'),
      endsAt: time('endsAt'),
    );
  }

  final String taskId;
  final String occurrenceId;

  /// Beginn der ganzen Sitzung; Grundlage für die gebrauchte Zeit.
  final DateTime startedAt;

  /// Beginn des laufenden Abschnitts (ändert sich bei „Noch 5 Minuten“); der
  /// Fortschritt des Countdowns bezieht sich darauf.
  final DateTime segmentStartedAt;
  final DateTime endsAt;

  Duration remaining(DateTime now) {
    final left = endsAt.difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  bool isOver(DateTime now) => !now.toUtc().isBefore(endsAt);

  /// Anteil des laufenden Abschnitts, der verstrichen ist (0 bis 1).
  double progress(DateTime now) {
    final total = endsAt.difference(segmentStartedAt).inMicroseconds;
    if (total <= 0) return 1;
    final done = now.toUtc().difference(segmentStartedAt).inMicroseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  /// Verlängert um [by]. Ist die Zeit schon um, beginnt der neue Abschnitt
  /// jetzt, sonst hängt er hinten an.
  FocusSession extended(Duration by, {required DateTime now}) {
    final utc = now.toUtc();
    final over = isOver(utc);
    final base = over ? utc : endsAt;
    return FocusSession(
      taskId: taskId,
      occurrenceId: occurrenceId,
      startedAt: startedAt,
      segmentStartedAt: over ? utc : segmentStartedAt,
      endsAt: base.add(by),
    );
  }

  /// Die gebrauchte Zeit seit dem Start in vollen Minuten (aufgerundet,
  /// mindestens eine); damit wird die Dauer beim Erledigen vorbelegt. Sie endet
  /// mit dem Countdown: Wer erst später auf „Fertig“ tippt, bekommt die Zeit
  /// danach nicht angerechnet.
  int elapsedMinutes(DateTime now) {
    final utc = now.toUtc();
    final end = utc.isBefore(endsAt) ? utc : endsAt;
    final micros = end.difference(startedAt).inMicroseconds;
    final minutes = (micros / Duration.microsecondsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// So lange nach dem Ende bleibt eine Sitzung erreichbar. Danach gilt sie als
  /// vergessen und stört nicht mehr.
  static const staleAfter = Duration(hours: 6);

  /// Ob die Sitzung vergessen ist: Ihr Ende liegt mindestens [staleAfter]
  /// zurück. Eine laufende Sitzung ist es nie, auch nicht über Mitternacht.
  bool isStale(DateTime now) => !now.toUtc().isBefore(endsAt.add(staleAfter));

  String toJson() => jsonEncode({
    'taskId': taskId,
    'occurrenceId': occurrenceId,
    'startedAt': startedAt.toIso8601String(),
    'segmentStartedAt': segmentStartedAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
  });
}
