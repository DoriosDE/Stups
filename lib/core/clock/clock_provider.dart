import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die Uhr der App; Tests können sie festlegen.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
