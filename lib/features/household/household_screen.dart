import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../shell/placeholder_page.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PlaceholderPage(title: l10n.tabHousehold, hint: l10n.householdHint);
  }
}
