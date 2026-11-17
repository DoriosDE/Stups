import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../inbox/inbox_providers.dart';
import '../inbox/inbox_view.dart';
import 'task_list.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  /// Der Tab öffnet mit der Inbox; „Alle Aufgaben“ ist die zweite Ansicht.
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inboxCount = ref.watch(inboxItemsProvider).value?.length ?? 0;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.tabTasks, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newTask),
            icon: const Icon(Icons.add),
            label: Text(l10n.taskNew),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text(l10n.tasksTabInbox(inboxCount)),
            ),
            ButtonSegment(value: true, label: Text(l10n.tasksTabAll)),
          ],
          selected: {_showAll},
          onSelectionChanged: (selection) =>
              setState(() => _showAll = selection.single),
        ),
        const SizedBox(height: 16),
        if (_showAll) const TaskList() else const InboxView(),
      ],
    );
  }
}
