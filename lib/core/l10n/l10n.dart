import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Delegates für die App. Der erzeugte `AppLocalizations.localizationsDelegates`
/// nimmt die veraltete `GlobalMaterialLocalizations` aus `flutter_localizations`;
/// zu `MaterialApp` aus `material_ui` passt die aus `material_ui`, deren
/// `delegates` auch die Widget- und Cupertino-Texte mitbringen.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Kurzform für die Texte der Oberfläche: `context.l10n.tabToday`.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
