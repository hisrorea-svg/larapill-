// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

/// 🗄️ Drift Database for Larapill Pharmacy System
///
/// This is the main database class that manages all tables and DAOs.
/// Generated code will be in app_database.g.dart

library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Tables
part 'tables/products_table.dart';
part 'tables/product_units_table.dart';
part 'tables/sales_table.dart';
part 'tables/sale_items_table.dart';
part 'tables/suppliers_table.dart';
part 'tables/purchase_orders_table.dart';
part 'tables/purchase_items_table.dart';
part 'tables/customer_debts_table.dart';
part 'tables/debt_payments_table.dart';
part 'tables/users_table.dart';
part 'tables/user_sessions_table.dart';
part 'tables/system_settings_table.dart';
part 'tables/pharmacy_settings_table.dart';
part 'tables/notifications_table.dart';
part 'tables/returns_table.dart';
part 'tables/return_items_table.dart';
part 'tables/audit_logs_table.dart';
part 'tables/sync_queue_table.dart';
part 'tables/daily_purchase_requests_table.dart';

// Generated code
part 'app_database.g.dart';

/// Main Drift database for the pharmacy application
@DriftDatabase(
  tables: [
    // Core
    Products,
    ProductUnits,
    // Sales
    Sales,
    SaleItems,
    // Purchases
    Suppliers,
    PurchaseOrders,
    PurchaseItems,
    DailyPurchaseRequests,
    // Debts
    CustomerDebts,
    DebtPayments,
    // Users
    Users,
    UserSessions,
    // Settings
    SystemSettings,
    PharmacySettings,
    // Notifications & Logs
    Notifications,
    AuditLogs,
    // Returns
    Returns,
    ReturnItems,
    // Sync
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations will be handled here
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Opens the database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'larapill_drift.db'));
    return NativeDatabase.createInBackground(file);
  });
}
