import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Hält den Bildschirm wach, solange es nötig ist (im Fokus, solange der
/// Countdown läuft). Eine Schnittstelle, damit Tests das Plugin nie anfassen,
/// wie bei den Erinnerungen.
abstract interface class ScreenAwake {
  /// Der Bildschirm soll nicht von selbst ausgehen.
  Future<void> keepOn();

  /// Der Bildschirm folgt wieder der Systemeinstellung.
  Future<void> release();
}

/// Die echte Umsetzung über `wakelock_plus`. Auf Android setzt es nur das
/// Fenster-Flag `FLAG_KEEP_SCREEN_ON`: keine Berechtigung, kein Google-Dienst.
///
/// Der Bildschirm bleibt ein Komfort. Schlägt es fehl, läuft der Fokus
/// trotzdem weiter.
class WakelockScreenAwake implements ScreenAwake {
  @override
  Future<void> keepOn() => _toggle(WakelockPlus.enable);

  @override
  Future<void> release() => _toggle(WakelockPlus.disable);

  Future<void> _toggle(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Bildschirm wach halten ging nicht: $error');
    }
  }
}

final screenAwakeProvider = Provider<ScreenAwake>(
  (ref) => WakelockScreenAwake(),
);
