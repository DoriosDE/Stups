import 'package:material_ui/material_ui.dart';

import 'core/l10n/l10n.dart';
import 'core/l10n/locale_resolution.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class StupsApp extends StatefulWidget {
  const StupsApp({
    super.key,
    this.localizationsDelegates = appLocalizationsDelegates,
  });

  /// Die Delegates für die Texte. Tests ersetzen sie durch eine
  /// Test-Übersetzung (siehe test/support/marker_localizations.dart).
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;

  @override
  State<StupsApp> createState() => _StupsAppState();
}

class _StupsAppState extends State<StupsApp> {
  final _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: StupsTheme.light,
      darkTheme: StupsTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: widget.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveLocale,
      routerConfig: _router,
    );
  }
}
