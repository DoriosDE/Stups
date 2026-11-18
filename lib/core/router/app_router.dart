import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/routines/routines_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/household/household_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/tasks/task_detail_screen.dart';
import '../../features/tasks/task_edit_screen.dart';
import '../../features/tasks/task_form_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/today/today_screen.dart';

abstract final class AppRoutes {
  static const today = '/heute';
  static const tasks = '/aufgaben';
  static const routines = '/routinen';
  static const household = '/haushalt';
  static const more = '/mehr';
  static const settings = '/einstellungen';
  static const newTask = '/aufgaben/neu';
  static const task = '/aufgaben/:id';
  static const editTask = '/aufgaben/:id/bearbeiten';

  /// Der Pfad zur Detailansicht der Aufgabe [id].
  static String taskPath(String id) => '/aufgaben/$id';

  /// Der Pfad zum Bearbeiten der Aufgabe [id].
  static String editTaskPath(String id) => '/aufgaben/$id/bearbeiten';
}

GoRouter createRouter({String initialLocation = AppRoutes.today}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.today, const TodayScreen()),
          _branch(AppRoutes.tasks, const TasksScreen()),
          _branch(AppRoutes.routines, const RoutinesScreen()),
          _branch(AppRoutes.household, const HouseholdScreen()),
          _branch(AppRoutes.more, const MoreScreen()),
        ],
      ),
      // Formulare und Detailansichten decken den Rahmen mit Tabs ab: eine Sache
      // pro Bildschirm.
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.newTask,
        builder: (context, state) => const TaskFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.task,
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.editTask,
        builder: (context, state) =>
            TaskEditScreen(taskId: state.pathParameters['id']!),
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
