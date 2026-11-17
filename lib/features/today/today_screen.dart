import 'package:material_ui/material_ui.dart';

import '../shell/placeholder_page.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Heute',
      hint: 'Hier steht bald dein nächster Schritt.',
    );
  }
}
