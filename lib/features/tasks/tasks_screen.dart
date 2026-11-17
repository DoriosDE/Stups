import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../inbox/inbox_view.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.tabTasks, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const InboxView(),
      ],
    );
  }
}
