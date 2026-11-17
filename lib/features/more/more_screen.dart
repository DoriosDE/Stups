import 'package:material_ui/material_ui.dart';

import '../shell/placeholder_page.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Mehr',
      hint: 'Rückblick, Einstellungen und Hilfe folgen.',
    );
  }
}
