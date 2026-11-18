import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/settings_providers.dart';
import 'companion.dart';

/// Schlüssel, an dem Tests das Konfetti erkennen.
const celebrationConfettiKey = Key('celebration-confetti');

/// Feiert eine erledigte Aufgabe: kurzes Vibrieren, dann ein Blatt mit
/// Konfetti, „+1 Tat“ und dem Begleiter. Haptik, Begleiter und Bewegung folgen
/// den Einstellungen und der Systemeinstellung „Bewegung reduzieren“.
///
/// Mit „Zu Heute“ geht es dorthin, mit „Hier bleiben“ oder einem Tipp daneben
/// bleibt die Person, wo sie ist.
Future<void> celebrate(
  BuildContext context,
  WidgetRef ref, {
  required String taskTitle,
}) async {
  final settings = ref.read(appSettingsProvider);
  // Die Feier wartet nicht auf das Vibrieren.
  if (settings.haptics) unawaited(_vibrate());
  if (!context.mounted) return;
  final reduceMotion =
      settings.reduceAnimations || MediaQuery.disableAnimationsOf(context);
  final toToday = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x9E1F1A3D),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => _CelebrationSheet(
      taskTitle: taskTitle,
      companionName:
          settings.companionName ?? context.l10n.companionDefaultName,
      showCompanion: settings.showCompanion,
      showConfetti: !reduceMotion,
    ),
  );
  if (toToday == true && context.mounted) context.go(AppRoutes.today);
}

/// Das Gerät kann eventuell nicht vibrieren; das ist kein Fehler.
Future<void> _vibrate() async {
  try {
    await HapticFeedback.mediumImpact();
  } catch (_) {}
}

class _CelebrationSheet extends StatelessWidget {
  const _CelebrationSheet({
    required this.taskTitle,
    required this.companionName,
    required this.showCompanion,
    required this.showConfetti,
  });

  final String taskTitle;
  final String companionName;
  final bool showCompanion;
  final bool showConfetti;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (showConfetti)
            const Positioned.fill(
              child: IgnorePointer(
                child: _Confetti(key: celebrationConfettiKey),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showCompanion)
                          // Die obere Hälfte ragt aus der Karte heraus.
                          const Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: 0.45,
                            child: Companion(
                              size: 110,
                              color: Color(0xFFC9BFFF),
                              cheering: true,
                            ),
                          ),
                        if (showCompanion) const SizedBox(height: 8),
                        Text(
                          l10n.taskDoneTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.celebrationDone(taskTitle),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 14),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.celebrationPlus,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSecondary,
                              ),
                            ),
                          ),
                        ),
                        if (showCompanion) ...[
                          const SizedBox(height: 10),
                          Text(
                            l10n.celebrationCompanion(companionName),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.celebrationToToday),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.celebrationStay),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Konfetti, das einmal herunterfällt und dann ruht.
class _Confetti extends StatefulWidget {
  const _Confetti({super.key});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2400);

  late final _controller = AnimationController(vsync: this, duration: _duration)
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConfettiPainter(_controller));
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this._progress) : super(repaint: _progress);

  final Animation<double> _progress;

  static const _colors = [
    Color(0xFFFFC93C),
    Color(0xFF19C39C),
    Color(0xFFFF6F61),
    Color(0xFF4DA8FF),
    Color(0xFFB9A8FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const pieces = 32;
    for (var i = 0; i < pieces; i++) {
      // Jedes Stück startet etwas später und fällt von oben bis unten durch.
      final delay = (i % 10) * 0.09 / 2.4;
      final t = ((_progress.value - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      final eased = Curves.easeOutCubic.transform(t);
      final x = size.width * ((i * 37 + 7) % 100) / 100;
      final y = -20 + (size.height + 40) * eased;
      final width = 8.0 + (i % 3) * 3;
      final height = 12.0 + (i % 4) * 2;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 6.28 * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(3),
        ),
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
