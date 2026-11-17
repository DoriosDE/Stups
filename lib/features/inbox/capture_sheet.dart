import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import 'inbox_providers.dart';

/// Öffnet das Eingabeblatt „Kopf frei machen“.
///
/// Die Spracheingabe läuft über die Diktierfunktion der Systemtastatur; dafür
/// braucht es nur ein gewöhnliches Textfeld.
Future<void> showCaptureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const CaptureSheet(),
  );
}

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Die Meldung gehört dem Scaffold unter dem Blatt, sie bleibt nach dem
    // Schließen stehen.
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.l10n.captureSaved;
    await ref.read(inboxRepositoryProvider).add(_controller.text);
    messenger.showSnackBar(SnackBar(content: Text(saved)));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.captureTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l10n.captureHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.captureFieldHint),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: value.text.trim().isEmpty ? null : _save,
                child: Text(l10n.captureDone),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
