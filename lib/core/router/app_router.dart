import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/routines/routines_screen.dart';
import '../../features/household/household_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/tasks/task_form_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/today/today_screen.dart';

abstract final class AppRoutes {
  static const today = '/heute';
  static const tasks = '/aufgaben';
  static const routines = '/routinen';
  static const household = '/haushalt';
  static const more = '/mehr';
  static const newTask = '/aufgaben/neu';
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
        path: AppRoutes.newTask,
        builder: (context, state) => const TaskFormScreen(),
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
