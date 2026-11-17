import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version und Paketangaben der laufenden App. Tests ersetzen den Provider,
/// damit sie ohne Plattformkanal auskommen.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
