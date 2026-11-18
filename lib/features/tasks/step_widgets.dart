import 'package:material_ui/material_ui.dart';

import '../../core/db/app_database.dart';
import '../../core/l10n/l10n.dart';

/// Die hervorgehobene Karte für den Schritt, der als Nächstes ansteht (oder ein
/// anderes Wort an derselben Stelle). Die Detailansicht der Aufgabe und der
/// Fokus zeigen ihn gleich.
///
/// [heading] steht klein über dem Inhalt; ohne sie trägt die Karte nur
/// [children].
class StepHighlightCard extends StatelessWidget {
  const StepHighlightCard({
    super.key,
    this.heading,
    required this.children,
    this.margin,
  });

  final String? heading;
  final List<Widget> children;

  /// Außenabstand der Karte; ohne Angabe gilt der Standard von [Card].
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(heading!, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Die weiteren Schritte unter „Danach“, nur zum Lesen.
class UpcomingStepsList extends StatelessWidget {
  const UpcomingStepsList({super.key, required this.steps, this.dense = false});

  final Iterable<Subtask> steps;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.taskNextSteps,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        for (final step in steps)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: dense,
            leading: const Icon(Icons.radio_button_unchecked),
            title: Text(step.title),
          ),
      ],
    );
  }
}
