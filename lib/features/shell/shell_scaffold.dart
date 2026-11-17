import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Rahmen mit den fünf Tabs und dem schwebenden Plus-Button „Kopf frei machen“.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations =
      <({String label, IconData icon, IconData selected})>[
        (
          label: 'Heute',
          icon: Icons.wb_sunny_outlined,
          selected: Icons.wb_sunny,
        ),
        (label: 'Aufgaben', icon: Icons.checklist, selected: Icons.checklist),
        (label: 'Routinen', icon: Icons.repeat, selected: Icons.repeat),
        (label: 'Haushalt', icon: Icons.home_outlined, selected: Icons.home),
        (label: 'Mehr', icon: Icons.more_horiz, selected: Icons.more_horiz),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: navigationShell),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Kopf frei machen',
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
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
