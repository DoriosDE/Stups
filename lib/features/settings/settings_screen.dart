import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/settings/settings_providers.dart';

/// Einstellungen. In v0.1 nur, was „Heute“ und die Feier brauchen: Begleiter,
/// Vibrieren und weniger Animationen. Weitere kommen mit ihren Features.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loaded = ref.watch(settingsStreamProvider).value;
    final repository = ref.read(settingsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        // Erst zeigen, wenn die Werte da sind, damit das Namensfeld gleich den
        // richtigen Namen trägt.
        child: loaded == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SwitchListTile(
                    title: Text(l10n.settingsCompanionShow),
                    value: loaded.showCompanion,
                    onChanged: repository.setShowCompanion,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextFormField(
                      initialValue: loaded.companionName,
                      decoration: InputDecoration(
                        labelText: l10n.settingsCompanionName,
                        hintText: l10n.companionDefaultName,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: repository.setCompanionName,
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsHaptics),
                    value: loaded.haptics,
                    onChanged: repository.setHaptics,
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsReduceAnimations),
                    subtitle: Text(l10n.settingsReduceAnimationsHint),
                    value: loaded.reduceAnimations,
                    onChanged: repository.setReduceAnimations,
                  ),
                ],
              ),
      ),
    );
  }
}
