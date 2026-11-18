import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';

/// Fragt nach dem Erledigen, wie viele Minuten es gedauert hat. Vorbelegt ist
/// die gemessene Zeit [measured] (aus dem Fokusmodus), sonst die Schätzung.
/// Liefert die Minuten, oder `null`, wenn das Blatt ohne Bestätigung
/// geschlossen wird.
Future<int?> showActualMinutesSheet(
  BuildContext context, {
  int? estimate,
  int? measured,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ActualMinutesSheet(initial: measured ?? estimate),
  );
}

class _ActualMinutesSheet extends StatefulWidget {
  const _ActualMinutesSheet({this.initial});

  final int? initial;

  @override
  State<_ActualMinutesSheet> createState() => _ActualMinutesSheetState();
}

class _ActualMinutesSheetState extends State<_ActualMinutesSheet> {
  late final _minutes = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(
            l10n.taskDoneAskTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _minutes,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.taskDoneMinutesLabel),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _minutes,
            builder: (context, value, _) {
              final minutes = int.tryParse(value.text);
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: minutes == null || minutes < 1
                      ? null
                      : () => Navigator.of(context).pop(minutes),
                  child: Text(l10n.taskDoneConfirm),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
