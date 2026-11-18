import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_info/app_info_provider.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../shell/placeholder_page.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(packageInfoProvider).value?.version;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PlaceholderPage(
            title: context.l10n.tabMore,
            hint: context.l10n.moreHint,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(context.l10n.settingsTitle),
          onTap: () => context.push(AppRoutes.settings),
        ),
        if (version != null)
          Padding(
            // Unten Platz für den schwebenden Plus-Button, damit er den Text
            // nicht verdeckt.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
            child: Text(
              context.l10n.moreVersion(version),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
