import 'package:material_ui/material_ui.dart';

import '../shell/placeholder_page.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Aufgaben',
      hint: 'Hier landen bald deine Aufgaben und die Inbox.',
    );
  }
}
