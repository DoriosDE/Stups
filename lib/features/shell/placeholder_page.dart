import 'package:material_ui/material_ui.dart';

/// Vorläufige Seite für Bereiche, die in späteren Tickets entstehen.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(hint, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
