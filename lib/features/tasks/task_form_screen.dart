import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/area_display_name.dart';
import '../../core/l10n/l10n.dart';
import 'task_providers.dart';
import 'task_repository.dart';

/// Formular für eine neue Aufgabe.
///
/// Oben stehen nur Titel und erster Mini-Schritt; alles Weitere ist unter „Mehr
/// Details“ eingeklappt (eine Sache pro Bildschirm).
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _title = TextEditingController();
  final _firstStep = TextEditingController();
  final _estimate = TextEditingController();
  final _steps = <TextEditingController>[];
  Priority _priority = Priority.b;
  DateTime? _dueDate;
  DateTime? _reminderAt;

  /// Gewählter Bereich; ohne Wahl gilt „Persönliches“.
  String? _areaId;

  @override
  void dispose() {
    _title.dispose();
    _firstStep.dispose();
    _estimate.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<Area> areas) async {
    await ref
        .read(taskRepositoryProvider)
        .create(
          TaskDraft(
            title: _title.text,
            areaId: _selectedAreaId(areas)!,
            firstStep: _firstStep.text,
            estimateMin: int.tryParse(_estimate.text),
            priority: _priority,
            steps: [for (final step in _steps) step.text],
            dueDate: _dueDate,
            reminderAt: _reminderAt,
          ),
        );
    if (mounted) context.pop();
  }

  /// Erst der Tag, dann die Uhrzeit (voreingestellt 9:00).
  Future<void> _pickReminder() async {
    final today = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 5),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(_reminderAt!),
    );
    if (time == null) return;
    setState(
      () => _reminderAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final areas = ref.watch(areasProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.taskNew)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.taskTitleLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstStep,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.taskFirstStepLabel),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(l10n.taskMoreDetails),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _estimate,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.taskEstimateLabel,
                  ),
                ),
                for (final step in _steps) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: step,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.taskStepLabel),
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _steps.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.taskAddStep),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.taskPriorityLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<Priority>(
                  showSelectedIcon: false,
                  segments: [
                    for (final priority in Priority.values)
                      ButtonSegment(
                        value: priority,
                        label: Text(priority.name.toUpperCase()),
                      ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) =>
                      setState(() => _priority = selection.single),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.taskAreaLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (areas != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final area in areas)
                        ChoiceChip(
                          label: Text(areaDisplayName(l10n, area)),
                          selected: _selectedAreaId(areas) == area.id,
                          onSelected: (_) => setState(() => _areaId = area.id),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.taskDueLabel),
                  subtitle: Text(
                    _dueDate == null
                        ? l10n.taskNotSet
                        : MaterialLocalizations.of(context)
                              .formatMediumDate(_dueDate!),
                  ),
                  trailing: _dueDate == null
                      ? null
                      : IconButton(
                          tooltip: l10n.taskClear,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                  onTap: _pickDueDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none),
                  title: Text(l10n.taskReminderLabel),
                  subtitle: Text(
                    _reminderAt == null
                        ? l10n.taskNotSet
                        : _formatReminder(context, _reminderAt!),
                  ),
                  trailing: _reminderAt == null
                      ? null
                      : IconButton(
                          tooltip: l10n.taskClear,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _reminderAt = null),
                        ),
                  onTap: _pickReminder,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _title,
              builder: (context, title, _) => FilledButton(
                onPressed: areas == null || title.text.trim().isEmpty
                    ? null
                    : () => _save(areas),
                child: Text(l10n.taskSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReminder(BuildContext context, DateTime reminder) {
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(reminder)}, '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(reminder))}';
  }

  /// Der gewählte Bereich, sonst „Persönliches“.
  String? _selectedAreaId(List<Area> areas) {
    if (_areaId != null) return _areaId;
    for (final area in areas) {
      if (area.builtInKey == BuiltInArea.personal) return area.id;
    }
    return null;
  }
}
