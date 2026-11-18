import 'package:stups/core/screen_awake/screen_awake.dart';

/// Merkt sich, ob die App den Bildschirm gerade wach hält, ohne das Plugin
/// anzufassen.
class FakeScreenAwake implements ScreenAwake {
  /// Ob der Bildschirm gerade wach gehalten wird.
  bool isOn = false;

  @override
  Future<void> keepOn() async => isOn = true;

  @override
  Future<void> release() async => isOn = false;
}
