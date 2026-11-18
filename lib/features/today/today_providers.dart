import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/app_database_provider.dart';
import '../../core/db/day_key.dart';
import '../tasks/task_providers.dart';
import 'day_plan_repository.dart';
import 'today_state.dart';

/// Die Uhr der App; Tests können sie festlegen.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Der heutige Kalendertag als `yyyy-MM-dd`. Er wechselt um Mitternacht von
/// selbst, auch wenn die App offen bleibt; war sie im Hintergrund, greift der
/// Wechsel beim Zurückkehren.
final todayKeyProvider = Provider<String>((ref) {
  final now = ref.watch(clockProvider)();
  final midnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return dayKey(now);
});

final dayPlanRepositoryProvider = Provider<DayPlanRepository>(
  (ref) => DayPlanRepository(ref.watch(appDatabaseProvider)),
);

/// Der Plan für einen Tag; `null`, solange es keinen gibt.
final dayPlanProvider = StreamProvider.family<DayPlan?, String>(
  (ref, day) => ref.watch(dayPlanRepositoryProvider).watchPlan(day),
);

/// Plan von heute zusammen mit den Aufgaben; lädt, bis beides da ist.
final todayStateProvider = Provider<AsyncValue<TodayState>>((ref) {
  final plan = ref.watch(dayPlanProvider(ref.watch(todayKeyProvider)));
  final tasks = ref.watch(taskListProvider(null));
  if (!plan.hasValue || !tasks.hasValue) return const AsyncLoading();
  return AsyncData(buildTodayState(plan.value, tasks.value!));
});

/// Der Taten-Zähler: so viele Aufgaben sind erledigt.
final deedCountProvider = StreamProvider<int>(
  (ref) => ref.watch(taskRepositoryProvider).watchDeedCount(),
);
