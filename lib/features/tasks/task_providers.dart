import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/app_database_provider.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(appDatabaseProvider)),
);

/// Die sichtbaren Bereiche (Haushalt, Arbeit, Persönliches und eigene).
final areasProvider = StreamProvider<List<Area>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAreas(),
);
