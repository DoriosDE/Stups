import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/l10n.dart';
import 'inbox_providers.dart';

/// Die Inbox: alles, was mit „Kopf frei machen“ festgehalten wurde.
class InboxView extends ConsumerWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxItemsProvider).value;
    if (items == null) return const SizedBox.shrink();
    if (items.isEmpty) return const _EmptyInbox();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.inboxIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        for (final item in items) _InboxRow(item: item),
      ],
    );
  }
}

class _InboxRow extends ConsumerWidget {
  const _InboxRow({required this.item});

  final InboxItem item;

  Future<void> _convertToTask(BuildContext context, WidgetRef ref) async {
    // Die Zeile verschwindet mit dem Eintrag; Messenger und Text vorher holen.
    final messenger = ScaffoldMessenger.of(context);
    final created = context.l10n.inboxTaskCreated;
    await ref.read(inboxRepositoryProvider).convertToTask(item.id);
    messenger.showSnackBar(SnackBar(content: Text(created)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(child: Text(item.content)),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _convertToTask(context, ref),
              child: Text(l10n.inboxToTask),
            ),
            IconButton(
              tooltip: l10n.inboxDelete(item.content),
              onPressed: () =>
                  ref.read(inboxRepositoryProvider).delete(item.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(l10n.inboxEmptyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.inboxEmptyText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
