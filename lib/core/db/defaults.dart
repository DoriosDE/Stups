import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// Neue ID für einen Datensatz: UUID v4 als Text (siehe docs/SPEC.md).
String newId() => _uuid.v4();

/// Aktueller Zeitpunkt in UTC für Spalten wie `createdAt`.
DateTime nowUtc() => DateTime.now().toUtc();
