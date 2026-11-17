import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';

/// Rahmen mit den fünf Tabs und dem schwebenden Plus-Button „Kopf frei machen“.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final _destinations =
      <
        ({
          String Function(AppLocalizations) label,
          IconData icon,
          IconData selected,
        })
      >[
        (
          label: (l10n) => l10n.tabToday,
          icon: Icons.wb_sunny_outlined,
          selected: Icons.wb_sunny,
        ),
        (
          label: (l10n) => l10n.tabTasks,
          icon: Icons.checklist,
          selected: Icons.checklist,
        ),
        (
          label: (l10n) => l10n.tabRoutines,
          icon: Icons.repeat,
          selected: Icons.repeat,
        ),
        (
          label: (l10n) => l10n.tabHousehold,
          icon: Icons.home_outlined,
          selected: Icons.home,
        ),
        (
          label: (l10n) => l10n.tabMore,
          icon: Icons.more_horiz,
          selected: Icons.more_horiz,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(child: navigationShell),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.captureTooltip,
        // Die Schnellerfassung folgt mit Ticket 03.
        onPressed: () {},
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selected),
              label: destination.label(l10n),
            ),
        ],
      ),
    );
  }
}
