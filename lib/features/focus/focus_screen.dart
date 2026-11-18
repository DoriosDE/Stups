import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/clock/clock_provider.dart';
import '../../core/db/app_database.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../tasks/actual_minutes_sheet.dart';
import '../tasks/task_providers.dart';
import '../tasks/task_repository.dart';
import '../today/celebration.dart';
import 'focus_providers.dart';
import 'focus_session.dart';

/// Die Dauern zur Auswahl; „Frei“ kommt als eigener Knopf dazu.
const _lengths = [5, 10, 15];

/// Wie lange „Noch 5 Minuten“ verlängert.
const _extension = Duration(minutes: 5);

/// Fokusmodus: im Vollbild eine Aufgabe, ihre Schritte und ein sichtbarer
/// Countdown (Prinzipien „Zeit sichtbar machen“ und „Ablenkung parken“).
///
/// Der Countdown liest den gespeicherten Endzeitpunkt gegen die Uhr; der
/// Sekundentakt und das Zurückkehren aus dem Hintergrund frischen nur die
/// Anzeige auf.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;

  /// Die zuletzt angezeigte Restzeit in Sekunden; nur wenn sie sich ändert,
  /// wird neu gezeichnet.
  int? _shownSeconds;

  /// Die Aufgabe ist erledigt oder die Sitzung beendet: der Bildschirm wird
  /// verlassen und zeigt nichts mehr.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Zurück aus dem Hintergrund: sofort die richtige Zeit zeigen.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _tick() {
    final session = ref.read(focusSessionProvider(widget.taskId)).value;
    if (session == null || !mounted) return;
    final now = ref.read(clockProvider)();
    final seconds = _secondsLeft(session, now);
    if (seconds != _shownSeconds) setState(() {});
  }

  Future<void> _start(Duration length) async {
    if (!await _confirmSwitch()) return;
    await ref.read(focusRepositoryProvider).start(widget.taskId, length);
  }

  /// Läuft der Fokus schon für eine andere Aufgabe, fragt ein Dialog, ob der
  /// neue ihn ersetzen soll. „Bei … bleiben“ geht zurück zu jener Aufgabe, ein
  /// Wegtippen des Dialogs ändert nichts. Liefert, ob der Start weitergehen darf.
  Future<bool> _confirmSwitch() async {
    final other = ref.read(runningElsewhereProvider(widget.taskId)).value;
    if (other == null) return true;
    final title = ref.read(taskDetailProvider(other.taskId)).value?.task.title;
    // Gibt es die andere Aufgabe nicht mehr, ist ihre Sitzung verwaist.
    if (title == null) return true;
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => _SwitchDialog(otherTitle: title),
    );
    if (!mounted) return false;
    if (replace == false) {
      context.pushReplacement(AppRoutes.focusPath(other.taskId));
    }
    return replace ?? false;
  }

  Future<void> _pickFree() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => const _FreeMinutesDialog(),
    );
    if (minutes != null) await _start(Duration(minutes: minutes));
  }

  Future<void> _extend() =>
      ref.read(focusRepositoryProvider).extend(_extension);

  /// „Fertig“: die Dauer abfragen (vorbelegt mit der gemessenen Zeit),
  /// erledigen, Sitzung beenden, feiern.
  Future<void> _finish(FocusSession session, TaskDetail detail) async {
    final now = ref.read(clockProvider)();
    final minutes = await showActualMinutesSheet(
      context,
      estimate: detail.task.estimateMin,
      measured: session.elapsedMinutes(now),
    );
    if (minutes == null || !mounted) return;
    await ref
        .read(taskRepositoryProvider)
        .complete(detail.task.id, actualMin: minutes);
    await ref.read(focusRepositoryProvider).stop();
    if (!mounted) return;
    setState(() => _leaving = true);
    await celebrate(context, ref, taskTitle: detail.task.title);
    if (mounted) context.go(AppRoutes.today);
  }

  /// „Für heute reicht’s“: Sitzung beenden, ohne Vorwurf zurück zu Heute.
  Future<void> _stop() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.focusStopped;
    final router = GoRouter.of(context);
    await ref.read(focusRepositoryProvider).stop();
    if (!mounted) return;
    setState(() => _leaving = true);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    router.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(taskDetailProvider(widget.taskId)).value;
    final sessionState = ref.watch(focusSessionProvider(widget.taskId));
    // Beides muss geladen sein, bevor man eine Dauer wählen kann: Erst dann
    // weiß die Rückfrage, ob sie nötig ist und wie die andere Aufgabe heißt.
    final elsewhere = ref.watch(runningElsewhereProvider(widget.taskId));
    final elsewhereTask = elsewhere.value == null
        ? null
        : ref.watch(taskDetailProvider(elsewhere.value!.taskId));
    final now = ref.watch(clockProvider)();
    final Widget body;
    if (_leaving ||
        detail == null ||
        !sessionState.hasValue ||
        !elsewhere.hasValue ||
        (elsewhereTask != null && !elsewhereTask.hasValue)) {
      body = const SizedBox.shrink();
    } else {
      final session = sessionState.value;
      _shownSeconds = session == null ? null : _secondsLeft(session, now);
      final list = ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            detail.task.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          if (session == null)
            _LengthPicker(
              onPicked: (minutes) => _start(Duration(minutes: minutes)),
              onFree: _pickFree,
            )
          else
            _Countdown(
              session: session,
              now: now,
              onMore: _extend,
              onDone: () => _finish(session, detail),
            ),
          if (session != null && !session.isOver(now))
            Center(
              child: TextButton(
                onPressed: () => _finish(session, detail),
                child: Text(context.l10n.focusDoneEarly),
              ),
            ),
          const SizedBox(height: 12),
          _Steps(subtasks: detail.subtasks),
          // Auch vor dem Start: Einfälle kommen nicht erst mit dem Countdown.
          const SizedBox(height: 16),
          _ParkingLot(occurrenceId: session?.occurrenceId),
        ],
      );
      body = Column(
        children: [
          Expanded(child: list),
          // „Für heute reicht’s“ bleibt immer in Reichweite.
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _stop,
            child: Text(context.l10n.focusStop),
          ),
          const SizedBox(height: 8),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: body),
    );
  }
}

/// Die Restzeit in ganzen Sekunden, aufgerundet: „0:00“ zeigt erst das Ende.
int _secondsLeft(FocusSession session, DateTime now) {
  final left = session.remaining(now);
  return (left.inMilliseconds / 1000).ceil();
}

String _formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Die Schritte: der erste hervorgehoben, die übrigen darunter.
class _Steps extends StatelessWidget {
  const _Steps({required this.subtasks});

  final List<Subtask> subtasks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final first = subtasks.firstOrNull;
    final later = subtasks.skip(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (first != null)
          Card(
            margin: EdgeInsets.zero,
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
                  Text(first.title, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        if (later.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.taskNextSteps, style: theme.textTheme.labelLarge),
          for (final step in later)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(step.title),
            ),
        ],
      ],
    );
  }
}

/// Die Rückfrage, wenn für eine andere Aufgabe schon ein Fokus läuft. Sie
/// liefert `true` für „Hier starten“ und `false` für „Bei … bleiben“.
class _SwitchDialog extends StatelessWidget {
  const _SwitchDialog({required this.otherTitle});

  final String otherTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.focusSwitchTitle(otherTitle)),
      content: Text(l10n.focusSwitchBody(otherTitle)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.focusSwitchStay(otherTitle)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.focusSwitchConfirm),
        ),
      ],
    );
  }
}

/// Die Wahl der Dauer vor dem Start.
class _LengthPicker extends StatelessWidget {
  const _LengthPicker({required this.onPicked, required this.onFree});

  final ValueChanged<int> onPicked;
  final VoidCallback onFree;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.focusPickTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final minutes in _lengths)
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(96, 56)),
                onPressed: () => onPicked(minutes),
                child: Text(l10n.focusMinutes(minutes)),
              ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 56)),
              onPressed: onFree,
              child: Text(l10n.focusFree),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dialog für eine frei gewählte Dauer.
class _FreeMinutesDialog extends StatefulWidget {
  const _FreeMinutesDialog();

  @override
  State<_FreeMinutesDialog> createState() => _FreeMinutesDialogState();
}

class _FreeMinutesDialogState extends State<_FreeMinutesDialog> {
  final _minutes = TextEditingController();

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.focusFreeTitle),
      content: TextField(
        controller: _minutes,
        autofocus: true,
        keyboardType: TextInputType.number,
        // Höchstens 999 Minuten: so bleibt die Zeitrechnung ohne Überlauf.
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(labelText: l10n.taskDoneMinutesLabel),
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _minutes,
          builder: (context, value, _) {
            final minutes = int.tryParse(value.text);
            return FilledButton(
              onPressed: minutes == null || minutes < 1
                  ? null
                  : () => Navigator.of(context).pop(minutes),
              child: Text(l10n.focusFreeConfirm),
            );
          },
        ),
      ],
    );
  }
}

/// Der Countdown als Ring mit der Restzeit; bei Zeitende stattdessen die
/// Wahl „Noch 5 Minuten“ oder „Fertig“.
class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.session,
    required this.now,
    required this.onMore,
    required this.onDone,
  });

  final FocusSession session;
  final DateTime now;
  final VoidCallback onMore;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final over = session.isOver(now);
    final time = _formatSeconds(_secondsLeft(session, now));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: l10n.focusRemaining(time),
            excludeSemantics: true,
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _RingPainter(
                  // Der Ring leert sich: voll am Anfang, leer am Ende.
                  remaining: 1 - session.progress(now),
                  track: theme.colorScheme.surfaceContainerHighest,
                  color: over
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                ),
                child: Center(
                  child: Text(time, style: theme.textTheme.displayMedium),
                ),
              ),
            ),
          ),
        ),
        if (over) ...[
          const SizedBox(height: 16),
          Text(
            l10n.focusTimeUp,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: onMore,
              child: Text(l10n.focusMoreFive),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
              ),
              onPressed: onDone,
              child: Text(l10n.focusDone),
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.remaining,
    required this.track,
    required this.color,
  });

  /// Anteil der Zeit, der noch übrig ist (0 bis 1).
  final double remaining;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (remaining > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * remaining,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.remaining != remaining || old.track != track || old.color != color;
}

/// Der Ablenkungs-Parkplatz: ein Feld für plötzliche Einfälle, die in der
/// Inbox landen, ohne den Countdown zu stören. [occurrenceId] ist das
/// Vorkommen der laufenden Sitzung; vor dem Start gibt es noch keines.
class _ParkingLot extends ConsumerStatefulWidget {
  const _ParkingLot({this.occurrenceId});

  final String? occurrenceId;

  @override
  ConsumerState<_ParkingLot> createState() => _ParkingLotState();
}

class _ParkingLotState extends ConsumerState<_ParkingLot> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _park() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.focusParked;
    // Das Feld wird erst geleert, wenn der Einfall sicher geparkt ist.
    await ref
        .read(focusRepositoryProvider)
        .park(_controller.text, occurrenceId: widget.occurrenceId);
    _controller.clear();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.focusParkTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(l10n.focusParkHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.captureFieldHint),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: value.text.trim().isEmpty ? null : _park,
                  child: Text(l10n.focusParkButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
