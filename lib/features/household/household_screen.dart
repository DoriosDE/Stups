import 'package:material_ui/material_ui.dart';

import '../shell/placeholder_page.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Haushalt',
      hint: 'Der Haushalt kommt in Version 0.3.',
    );
  }
}
