import 'package:flutter_test/flutter_test.dart';
import 'package:stups/features/focus/focus_session.dart';

void main() {
  final start = DateTime.utc(2026, 11, 18, 9, 0);

  FocusSession fiveMinutes() => FocusSession.start(
    taskId: 't1',
    occurrenceId: 'o1',
    now: start,
    length: const Duration(minutes: 5),
  );

  test('der Endzeitpunkt liegt die gewählte Dauer nach dem Start', () {
    expect(fiveMinutes().endsAt, DateTime.utc(2026, 11, 18, 9, 5));
  });

  test(
    'die Restzeit ergibt sich aus der Uhr, nicht aus gezählten Sekunden',
    () {
      final session = fiveMinutes();

      expect(session.remaining(start), const Duration(minutes: 5));
      // Die App war 4 Minuten im Hintergrund: ein Blick auf die Uhr genügt.
      expect(
        session.remaining(start.add(const Duration(minutes: 4))),
        const Duration(minutes: 1),
      );
    },
  );

  test('nach dem Ende ist die Restzeit null, nie negativ', () {
    final session = fiveMinutes();
    final late = start.add(const Duration(minutes: 9));

    expect(session.remaining(late), Duration.zero);
    expect(session.isOver(late), isTrue);
    expect(session.isOver(start.add(const Duration(minutes: 4))), isFalse);
    expect(session.isOver(DateTime.utc(2026, 11, 18, 9, 5)), isTrue);
  });

  test('der Fortschritt läuft von 0 bis 1', () {
    final session = fiveMinutes();

    expect(session.progress(start), 0);
    expect(
      session.progress(start.add(const Duration(minutes: 1, seconds: 15))),
      0.25,
    );
    expect(session.progress(start.add(const Duration(hours: 1))), 1);
  });

  test(
    '„Noch 5 Minuten“ beginnt bei Zeitende neu, mit eigenem Fortschritt',
    () {
      final session = fiveMinutes();
      final over = start.add(const Duration(minutes: 7));

      final more = session.extended(const Duration(minutes: 5), now: over);

      expect(more.endsAt, over.add(const Duration(minutes: 5)));
      expect(more.isOver(over), isFalse);
      expect(more.progress(over), 0);
      // Der Start der Sitzung bleibt, damit die gebrauchte Zeit stimmt.
      expect(more.startedAt, start);
    },
  );

  test('die gebrauchte Zeit zählt ab Start der Sitzung, auf volle Minuten '
      'aufgerundet, mindestens eine', () {
    final session = fiveMinutes();

    expect(session.elapsedMinutes(start), 1);
    expect(session.elapsedMinutes(start.add(const Duration(minutes: 3))), 3);
    expect(
      session.elapsedMinutes(start.add(const Duration(minutes: 3, seconds: 1))),
      4,
    );
  });

  test('eine Sitzung von gestern ist veraltet', () {
    // Ortszeit, damit der Test in jeder Zeitzone gleich läuft.
    final session = FocusSession.start(
      taskId: 't1',
      occurrenceId: 'o1',
      now: DateTime(2026, 11, 18, 12, 0),
      length: const Duration(minutes: 5),
    );

    expect(session.isFromDay(DateTime(2026, 11, 18, 23, 0)), isTrue);
    expect(session.isFromDay(DateTime(2026, 11, 19, 0, 5)), isFalse);
  });

  test('übersteht das Speichern als Text', () {
    final session = fiveMinutes().extended(
      const Duration(minutes: 5),
      now: start.add(const Duration(minutes: 6)),
    );

    final restored = FocusSession.fromJson(session.toJson());

    expect(restored.taskId, 't1');
    expect(restored.occurrenceId, 'o1');
    expect(restored.startedAt, session.startedAt);
    expect(restored.endsAt, session.endsAt);
    expect(restored.segmentStartedAt, session.segmentStartedAt);
  });
}
