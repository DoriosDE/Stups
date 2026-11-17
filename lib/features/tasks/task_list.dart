import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/area_display_name.dart';
import '../../core/l10n/l10n.dart';
import 'task_providers.dart';
import 'task_repository.dart';

/// Die Liste aller Aufgaben mit Bereichs-Chips zum Filtern.
class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  /// Gewählter Bereich; `null` zeigt alle.
  String? _areaId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = ref.watch(taskListProvider(_areaId)).value ?? const [];
    final areaList = ref.watch(areasProvider).value ?? const <Area>[];
    final areas = {for (final area in areaList) area.id: area};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.tasksAreaAll),
              selected: _areaId == null,
              onSelected: (_) => setState(() => _areaId = null),
            ),
            for (final area in areaList)
              ChoiceChip(
                label: Text(areaDisplayName(l10n, area)),
                selected: _areaId == area.id,
                onSelected: (_) => setState(() => _areaId = area.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(l10n.tasksEmpty, style: Theme.of(context).textTheme.bodyMedium),
        for (final entry in entries)
          _TaskRow(entry: entry, area: areas[entry.task.areaId]),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.entry, required this.area});

  final TaskListEntry entry;

  /// Fehlt, wenn der Bereich ausgeblendet ist.
  final Area? area;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = entry.task;
    final meta = [
      if (area != null) areaDisplayName(l10n, area!),
      if (task.estimateMin != null) l10n.taskMinutes(task.estimateMin!),
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _PriorityBadge(priority: task.priority),
      title: Text(
        task.title,
        style: entry.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: meta.isEmpty ? null : Text(meta),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      Priority.a => (scheme.primary, scheme.onPrimary),
      Priority.b => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      Priority.c => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
