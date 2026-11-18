import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/area_display_name.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/settings_providers.dart';
import '../inbox/capture_sheet.dart';
import '../tasks/task_providers.dart';
import '../tasks/task_repository.dart';
import 'companion.dart';
import 'today_providers.dart';
import 'today_state.dart';

/// „Heute“: erst die Energie-Frage, danach groß nur der nächste Schritt, der
/// Rest des Tagesplans eingeklappt (Prinzip „Eine Sache pro Bildschirm“).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(todayStateProvider).value;
    final deeds = ref.watch(deedCountProvider).value ?? 0;
    final date = MaterialLocalizations.of(context)
        .formatFullDate(ref.watch(clockProvider)());
    return ListView(
      // Unten Platz für den schwebenden Plus-Button.
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Row(
          children: [
            Expanded(child: Text(date, style: theme.textTheme.bodyMedium)),
            _DeedsChip(count: deeds, label: l10n.todayDeeds(deeds)),
          ],
        ),
        const SizedBox(height: 12),
        if (state != null) ...[
          _MainCard(state: state),
          if (state.plan.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PlanTile(state: state),
          ],
        ],
      ],
    );
  }
}

/// Der Taten-Zähler, berechnet aus den erledigten Vorkommen.
class _DeedsChip extends StatelessWidget {
  const _DeedsChip({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: scheme.onSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.onSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die große Karte: Begrüßung und je nach Stand Energie-Frage, nächster
/// Schritt, „Für heute geschafft“ oder „Alles ruhig“.
class _MainCard extends ConsumerStatefulWidget {
  const _MainCard({required this.state});

  final TodayState state;

  @override
  ConsumerState<_MainCard> createState() => _MainCardState();
}

class _MainCardState extends ConsumerState<_MainCard> {
  /// „Energie ändern“ wurde getippt: der Energie-Check ist wieder offen.
  bool _changingEnergy = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider);
    final name = settings.companionName ?? l10n.companionDefaultName;
    final next = state.next;
    final Widget content;
    if (_changingEnergy) {
      content = _EnergyCheck(
        onChosen: () => setState(() => _changingEnergy = false),
      );
    } else if (next != null) {
      content = _NextStep(
        entry: next,
        onChangeEnergy: () => setState(() => _changingEnergy = true),
      );
    } else if (state.energy == null) {
      content = state.hasMore ? const _EnergyCheck() : const _Quiet();
    } else if (state.plan.isNotEmpty) {
      content = _DayDone(state: state);
    } else {
      content = _Quiet(state: state);
    }
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onPrimary),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (settings.showCompanion) ...[
                Row(
                  children: [
                    const Companion(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.todayGreeting(name),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              content,
            ],
          ),
        ),
      ),
    );
  }
}

/// Knopf auf der Karte: umgekehrte Farben, damit er sich abhebt.
ButtonStyle _onCardStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: scheme.onPrimary,
    foregroundColor: scheme.primary,
    minimumSize: const Size(0, 56),
  );
}

ButtonStyle _quietOnCardStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return TextButton.styleFrom(
    foregroundColor: scheme.onPrimary,
    minimumSize: const Size(0, 48),
  );
}

class _EnergyCheck extends ConsumerWidget {
  const _EnergyCheck({this.onChosen});

  /// Wird gerufen, nachdem die Energie gewählt wurde.
  final VoidCallback? onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final day = ref.watch(todayKeyProvider);
    final labels = {
      Energy.low: l10n.energyLow,
      Energy.medium: l10n.energyMedium,
      Energy.high: l10n.energyHigh,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.todayEnergyQuestion,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (index, entry) in labels.entries.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: _onCardStyle(context),
                  onPressed: () async {
                    await ref
                        .read(dayPlanRepositoryProvider)
                        .chooseEnergy(day, entry.key);
                    onChosen?.call();
                  },
                  child: Text(entry.value),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.todayEnergyNote, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _NextStep extends ConsumerWidget {
  const _NextStep({required this.entry, required this.onChangeEnergy});

  final TaskListEntry entry;
  final VoidCallback onChangeEnergy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = entry.task;
    final day = ref.watch(todayKeyProvider);
    final areas = ref.watch(areasProvider).value ?? const <Area>[];
    final area = areas.where((a) => a.id == task.areaId).firstOrNull;
    final firstStep = ref
        .watch(taskDetailProvider(task.id))
        .value
        ?.subtasks
        .firstOrNull;
    final meta = [
      ?(area == null ? null : areaDisplayName(l10n, area)),
      ?(task.estimateMin == null
          ? null
          : l10n.taskEstimateAbout(task.estimateMin!)),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.onPrimary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.todayNextStep, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                if (firstStep != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.todayFirstMiniStep(firstStep.title),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              textStyle: theme.textTheme.titleMedium,
            ),
            onPressed: () => context.push(AppRoutes.taskPath(task.id)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.todayStart),
                const SizedBox(width: 8),
                const Icon(Icons.play_arrow),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: _quietOnCardStyle(context),
                onPressed: () => ref
                    .read(dayPlanRepositoryProvider)
                    .dropFromPlan(day, task.id),
                child: Text(l10n.todayTomorrowAgain),
              ),
            ),
            Expanded(
              child: TextButton(
                style: _quietOnCardStyle(context),
                onPressed: onChangeEnergy,
                child: Text(l10n.todayChangeEnergy),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayDone extends StatelessWidget {
  const _DayDone({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.todayDayDone,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        if (state.hasMore) _MoreButton(),
      ],
    );
  }
}

class _MoreButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.onPrimary, width: 2),
          minimumSize: const Size(0, 52),
        ),
        onPressed: () => ref
            .read(dayPlanRepositoryProvider)
            .addOneMore(ref.read(todayKeyProvider)),
        child: Text(context.l10n.todayOneMore),
      ),
    );
  }
}

/// Nichts zu tun: „Alles ruhig“, mit dem Weg zu „Kopf frei machen“. Gibt es
/// außerhalb des Plans noch Aufgaben, bleibt „Doch noch eine Aufgabe“.
class _Quiet extends StatelessWidget {
  const _Quiet({this.state});

  final TodayState? state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.todayQuiet,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          style: _onCardStyle(context),
          onPressed: () => showCaptureSheet(context),
          child: Text(l10n.captureTitle),
        ),
        if (state?.hasMore ?? false) _MoreButton(),
      ],
    );
  }
}

/// Der Tagesplan, eingeklappt: so steht er da, ohne zu drängen.
class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(l10n.todayPlanTitle, style: theme.textTheme.titleMedium),
        subtitle: Text(l10n.todayProgress(state.doneCount, state.plan.length)),
        children: [
          for (final entry in state.plan)
            ListTile(
              leading: Icon(
                entry.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: entry.done ? theme.colorScheme.tertiary : null,
              ),
              title: Text(
                entry.task.title,
                style: entry.done
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              onTap: () => context.push(AppRoutes.taskPath(entry.task.id)),
            ),
        ],
      ),
    );
  }
}
