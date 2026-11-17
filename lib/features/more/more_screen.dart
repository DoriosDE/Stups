import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_info/app_info_provider.dart';
import '../shell/placeholder_page.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(packageInfoProvider).value?.version;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: PlaceholderPage(
            title: 'Mehr',
            hint: 'Rückblick, Einstellungen und Hilfe folgen.',
          ),
        ),
        if (version != null)
          Padding(
            // Unten Platz für den schwebenden Plus-Button, damit er den Text
            // nicht verdeckt.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
            child: Text(
              'Version $version',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
