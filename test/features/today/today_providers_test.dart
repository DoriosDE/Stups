import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/features/today/today_providers.dart';

void main() {
  testWidgets('der heutige Tag wechselt um Mitternacht von selbst', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 18, 23, 0);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    final seen = <String>[];
    container.listen(todayKeyProvider, (_, key) => seen.add(key));
    expect(container.read(todayKeyProvider), '2026-11-18');

    now = DateTime(2026, 11, 19, 0, 0, 1);
    await tester.pump(const Duration(hours: 1, seconds: 1));

    expect(container.read(todayKeyProvider), '2026-11-19');
    expect(seen, ['2026-11-19']);
  });
}
