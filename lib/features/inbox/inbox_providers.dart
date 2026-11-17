import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database_provider.dart';
import 'inbox_repository.dart';

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.watch(appDatabaseProvider)),
);
