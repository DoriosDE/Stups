import 'package:material_ui/material_ui.dart';

/// Design-Tokens aus dem Prototyp (siehe prototypes/README.md).
abstract final class StupsColors {
  // Hell
  static const background = Color(0xFFF6F4FF);
  static const ink = Color(0xFF1F1A3D);
  static const primary = Color(0xFF5B3DF5);
  static const primaryEdge = Color(0xFF3B289F);
  static const primaryTint = Color(0xFFEBE8FE);
  static const start = Color(0xFFFFC93C);
  static const startEdge = Color(0xFFD9A514);
  static const done = Color(0xFF19C39C);

  // Dunkel
  static const darkBackground = Color(0xFF15122B);
  static const darkSurface = Color(0xFF211C42);
  static const darkInk = Color(0xFFF2EFFF);
  static const darkPrimary = Color(0xFF9D8BFF);
  static const darkPrimaryTint = Color(0xFF2E2766);

  /// Pastelltöne je Wochentag, Montag bis Sonntag.
  static const weekdays = <Color>[
    Color(0xFFFFE3DE),
    Color(0xFFDDF7EE),
    Color(0xFFE6E0FF),
    Color(0xFFFFF1CC),
    Color(0xFFDCEEFF),
    Color(0xFFFFE0F0),
    Color(0xFFECEAF4),
  ];
}

abstract final class StupsFonts {
  static const heading = 'Fredoka';
  static const body = 'Lexend';
}
