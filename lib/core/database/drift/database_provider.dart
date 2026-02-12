/// 🗄️ Drift Database Providers
///
/// Provides Riverpod integration for the Drift database.
library database_provider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daos/daos.dart';
import 'app_database.dart';

/// Private singleton instance
AppDatabase? _dbInstance;

/// Get or create the singleton database instance
AppDatabase _getDatabase() {
  _dbInstance ??= AppDatabase();
  return _dbInstance!;
}

/// Global database instance provider
///
/// ✅ Uses singleton pattern to ensure all providers share the same database connection
///
/// Usage:
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// final products = await db.select(db.products).get();
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // ✅ Use singleton - all providers share the same database instance
  final db = _getDatabase();
  // Note: We don't dispose here because the database is a singleton
  // and should live for the entire app lifetime
  return db;
});

/// Database Provider Helper - Singleton for non-Riverpod access
///
/// Use this ONLY when you cannot use Riverpod (inside classes without ref access).
/// Prefer using appDatabaseProvider when possible.
class DatabaseProviderHelper {
  /// Get the singleton database instance
  static AppDatabase get instance => _getDatabase();

  /// Close the database (call on app shutdown)
  static Future<void> close() async {
    await _dbInstance?.close();
    _dbInstance = null;
  }
}

final inventoryTransactionDriftDaoProvider =
    Provider<InventoryTransactionDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryTransactionDriftDao(db);
});

/// Provider for ExpenseDriftDao
final expenseDriftDaoProvider = Provider<ExpenseDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExpenseDriftDao(db);
});
