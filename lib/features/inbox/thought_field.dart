import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';

/// Das Textfeld für einen plötzlichen Einfall, im Eingabeblatt „Kopf frei
/// machen“ und im Ablenkungs-Parkplatz des Fokus. Die Spracheingabe läuft über
/// die Diktierfunktion der Systemtastatur.
class ThoughtField extends StatelessWidget {
  const ThoughtField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 3,
  });

  final TextEditingController controller;
  final bool autofocus;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: context.l10n.captureFieldHint),
    );
  }
}
