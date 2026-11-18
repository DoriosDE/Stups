import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/area_display_name.dart';
import '../../core/l10n/l10n.dart';
import 'task_providers.dart';
import 'task_repository.dart';

/// Formular für eine neue Aufgabe, oder, mit [initial], zum Bearbeiten.
///
/// Oben stehen nur Titel und erster Mini-Schritt; alles Weitere ist unter „Mehr
/// Details“ eingeklappt (eine Sache pro Bildschirm).
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.initial});

  /// Die Aufgabe, die bearbeitet wird; `null` legt eine neue an.
  final TaskDetail? initial;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

/// Ein Schrittfeld im Formular. Bei einem bestehenden Schritt trägt es dessen
/// [id], damit die Haken beim Speichern an ihm bleiben.
class _StepField {
  _StepField({this.id, String? text})
    : controller = TextEditingController(text: text);

  final String? id;
  final TextEditingController controller;

  StepDraft toDraft() => id == null
      ? StepDraft(controller.text)
      : StepDraft.existing(id!, controller.text);
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _estimate;

  /// Die Schritte der Aufgabe. Das erste Feld ist immer da: der allererste
  /// Mini-Schritt, oben im Formular; die übrigen stehen unter „Mehr Details“.
  late final List<_StepField> _steps;
  late Priority _priority;
  late DateTime? _dueDate;
  late DateTime? _reminderAt;

  /// Gewählter Bereich; ohne Wahl gilt „Persönliches“.
  String? _areaId;

  @override
  void initState() {
    super.initState();
    final task = widget.initial?.task;
    _title = TextEditingController(text: task?.title);
    _estimate = TextEditingController(text: task?.estimateMin?.toString());
    _steps = [
      for (final step in widget.initial?.subtasks ?? const <Subtask>[])
        _StepField(id: step.id, text: step.title),
    ];
    if (_steps.isEmpty) _steps.add(_StepField());
    _priority = task?.priority ?? Priority.b;
    _dueDate = task?.dueDate == null ? null : DateTime.parse(task!.dueDate!);
    _reminderAt = task?.reminderAt;
    _areaId = task?.areaId;
  }

  @override
  void dispose() {
    _title.dispose();
    _estimate.dispose();
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<Area> areas) async {
    final draft = TaskDraft(
      title: _title.text,
      areaId: _selectedAreaId(areas)!,
      estimateMin: int.tryParse(_estimate.text),
      priority: _priority,
      steps: [for (final step in _steps) step.toDraft()],
      dueDate: _dueDate,
      reminderAt: _reminderAt,
    );
    final repository = ref.read(taskRepositoryProvider);
    final initial = widget.initial;
    if (initial == null) {
      await repository.create(draft);
    } else {
      await repository.update(initial.task.id, draft);
    }
    if (mounted) context.pop();
  }

  /// Der früheste Tag, den der Dialog anbietet: [earliest], oder der schon
  /// gewählte Tag, wenn er davor liegt. Sonst bricht der Dialog ab, weil sein
  /// Startwert vor dem ersten Tag läge.
  DateTime _firstSelectable(DateTime earliest, DateTime? chosen) {
    if (chosen == null) return earliest;
    final day = DateTime(chosen.year, chosen.month, chosen.day);
    return day.isBefore(earliest) ? day : earliest;
  }

  /// Erst der Tag, dann die Uhrzeit (voreingestellt 9:00).
  Future<void> _pickReminder() async {
    final today = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? today,
      firstDate: _firstSelectable(
        DateTime(today.year, today.month, today.day),
        _reminderAt,
      ),
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
      firstDate: _firstSelectable(DateTime(today.year - 1), _dueDate),
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final areas = ref.watch(areasProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l10n.taskNew : l10n.taskEditTitle),
      ),
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
              controller: _steps.first.controller,
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
                for (final step in _steps.skip(1)) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: step.controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.taskStepLabel),
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _steps.add(_StepField())),
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
