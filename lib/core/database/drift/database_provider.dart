/// 🗄️ Drift Database Providers
///
/// Provides Riverpod integration for the Drift database.
/// This replaces the old DatabaseHelper singleton pattern.
library database_provider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Global database instance provider
///
/// Usage:
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// final products = await db.select(db.products).get();
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Legacy database helper reference (for migration period)
///
/// This allows gradual migration from DatabaseHelper to AppDatabase.
/// @deprecated Use appDatabaseProvider instead
@Deprecated('Use appDatabaseProvider instead - will be removed after migration')
final legacyDatabaseHelperProvider = Provider((ref) {
  // ignore: deprecated_member_use_from_same_package
  return ref.read(appDatabaseProvider);
});
