import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/local/app_database.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}
