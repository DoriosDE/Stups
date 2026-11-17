import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/area_display_name.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import 'actual_minutes_sheet.dart';
import 'task_providers.dart';
import 'task_repository.dart';

/// Eine Aufgabe ansehen: der erste Mini-Schritt groß, der Rest darunter.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(taskDetailProvider(taskId)).value;
    final areas = ref.watch(areasProvider).value ?? const <Area>[];
    final area = detail == null
        ? null
        : areas.where((a) => a.id == detail.task.areaId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: area == null ? null : Text(areaDisplayName(l10n, area)),
        actions: [
          IconButton(
            tooltip: l10n.taskEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editTaskPath(taskId)),
          ),
        ],
      ),
      body: SafeArea(
        child: detail == null
            ? const SizedBox.shrink()
            : _TaskBody(detail: detail),
      ),
    );
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.detail});

  final TaskDetail detail;

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final minutes = await showActualMinutesSheet(
      context,
      estimate: detail.task.estimateMin,
    );
    if (minutes == null) return;
    await ref
        .read(taskRepositoryProvider)
        .complete(detail.task.id, actualMin: minutes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final material = MaterialLocalizations.of(context);
    final task = detail.task;
    final due = task.dueDate == null ? null : DateTime.parse(task.dueDate!);
    final reminder = task.reminderAt;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(
                l10n.taskPriorityValue(task.priority.name.toUpperCase()),
              ),
            ),
            if (task.estimateMin != null)
              Chip(label: Text(l10n.taskEstimateAbout(task.estimateMin!))),
          ],
        ),
        const SizedBox(height: 12),
        Text(task.title, style: theme.textTheme.headlineSmall),
        if (task.firstStep != null) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taskFirstStepHeading,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(task.firstStep!, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
        if (detail.subtasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.taskNextSteps, style: theme.textTheme.labelLarge),
          for (final step in detail.subtasks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(step.title),
            ),
        ],
        if (due != null) ...[
          const SizedBox(height: 16),
          Text(l10n.taskDueOn(material.formatMediumDate(due))),
        ],
        if (reminder != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.taskReminderAt(
              '${material.formatMediumDate(reminder)}, '
              '${material.formatTimeOfDay(TimeOfDay.fromDateTime(reminder))}',
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (detail.occurrence case final done?)
          _DoneCard(estimateMin: task.estimateMin, actualMin: done.actualMin)
        else
          FilledButton(
            onPressed: () => _complete(context, ref),
            child: Text(l10n.taskDone),
          ),
      ],
    );
  }
}

/// Zeigt eine erledigte Aufgabe: Schätzung neben tatsächlicher Dauer, ohne
/// Bewertung.
class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.estimateMin, required this.actualMin});

  final int? estimateMin;
  final int? actualMin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final comparison = switch ((estimateMin, actualMin)) {
      (final estimate?, final actual?) => l10n.taskComparison(estimate, actual),
      (null, final actual?) => l10n.taskActualOnly(actual),
      _ => null,
    };
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(l10n.taskDoneTitle, style: theme.textTheme.titleLarge),
              if (comparison != null) ...[
                const SizedBox(height: 4),
                Text(comparison, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
