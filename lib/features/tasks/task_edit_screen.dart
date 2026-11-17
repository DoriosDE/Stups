import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'task_form_screen.dart';
import 'task_providers.dart';

/// Lädt eine Aufgabe und zeigt sie im Formular zum Bearbeiten.
///
/// Das Formular übernimmt die Angaben nur einmal beim Öffnen; spätere
/// Änderungen an der Datenbank überschreiben keine Eingaben.
class TaskEditScreen extends ConsumerWidget {
  const TaskEditScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(taskDetailProvider(taskId)).value;
    if (detail == null) return const Scaffold();
    return TaskFormScreen(key: ValueKey(taskId), initial: detail);
  }
}
