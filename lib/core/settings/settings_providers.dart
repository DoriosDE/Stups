import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database_provider.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final settingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Die Einstellungen; bis sie geladen sind, gelten die Voreinstellungen.
final appSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsStreamProvider).value ?? const AppSettings(),
);
