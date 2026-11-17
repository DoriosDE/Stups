import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stups/core/app_info/app_info_provider.dart';
import 'package:stups/features/more/more_screen.dart';

void main() {
  testWidgets('„Mehr“ zeigt die Version der App', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Stups Dev',
              packageName: 'de.dorios.stups.dev',
              version: '0.1.0-dev',
              buildNumber: '1000',
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: MoreScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version 0.1.0-dev'), findsOneWidget);
  });
}
