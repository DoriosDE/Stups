import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Hell- und Dunkel-Theme von Stups. Schriftgrößen folgen der Systemeinstellung,
/// weil nirgends feste Skalierungen gesetzt werden.
abstract final class StupsTheme {
  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: StupsColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: StupsColors.primary,
      onPrimary: Colors.white,
      primaryContainer: StupsColors.primaryTint,
      onPrimaryContainer: StupsColors.primaryEdge,
      secondary: StupsColors.start,
      onSecondary: StupsColors.ink,
      tertiary: StupsColors.done,
      surface: StupsColors.background,
      onSurface: StupsColors.ink,
    ),
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: StupsColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: StupsColors.darkPrimary,
      onPrimary: StupsColors.darkBackground,
      primaryContainer: StupsColors.darkPrimaryTint,
      onPrimaryContainer: StupsColors.darkInk,
      secondary: StupsColors.start,
      onSecondary: StupsColors.ink,
      tertiary: StupsColors.done,
      surface: StupsColors.darkBackground,
      onSurface: StupsColors.darkInk,
      surfaceContainer: StupsColors.darkSurface,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: StupsFonts.body,
    );
    TextStyle heading(TextStyle? s, FontWeight w) => (s ?? const TextStyle())
        .copyWith(fontFamily: StupsFonts.heading, fontWeight: w);
    final t = base.textTheme;
    return base.copyWith(
      textTheme: t.copyWith(
        displayLarge: heading(t.displayLarge, FontWeight.w700),
        displayMedium: heading(t.displayMedium, FontWeight.w700),
        displaySmall: heading(t.displaySmall, FontWeight.w700),
        headlineLarge: heading(t.headlineLarge, FontWeight.w700),
        headlineMedium: heading(t.headlineMedium, FontWeight.w700),
        headlineSmall: heading(t.headlineSmall, FontWeight.w600),
        titleLarge: heading(t.titleLarge, FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.brightness == Brightness.light
            ? Colors.white
            : StupsColors.darkSurface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: StupsFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: StupsColors.start,
        foregroundColor: StupsColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      // Große Touchflächen als Grundanforderung.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
