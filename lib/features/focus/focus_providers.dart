import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database_provider.dart';
import '../today/today_providers.dart';
import 'focus_repository.dart';
import 'focus_session.dart';

final focusRepositoryProvider = Provider<FocusRepository>(
  (ref) => FocusRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  ),
);

/// Die laufende Fokus-Sitzung zur Aufgabe [taskId]; `null`, wenn es für sie
/// keine gibt. Eine Sitzung von gestern gilt als vergessen.
final focusSessionProvider = StreamProvider.family<FocusSession?, String>((
  ref,
  taskId,
) {
  final clock = ref.watch(clockProvider);
  return ref
      .watch(focusRepositoryProvider)
      .watch()
      .map(
        (session) =>
            session != null &&
                session.taskId == taskId &&
                session.isFromDay(clock())
            ? session
            : null,
      );
});
