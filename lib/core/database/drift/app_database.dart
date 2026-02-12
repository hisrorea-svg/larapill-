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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'daos/daos.dart';

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
part 'daos/inventory_transaction_drift_dao.dart';
part 'tables/user_sessions_table.dart';
part 'tables/system_settings_table.dart';
part 'tables/pharmacy_settings_table.dart';
part 'tables/notifications_table.dart';
part 'tables/returns_table.dart';
part 'tables/return_items_table.dart';
part 'tables/audit_logs_table.dart';
part 'tables/sync_queue_table.dart';
part 'tables/daily_purchase_requests_table.dart';
part 'tables/stock_movements_table.dart';
part 'tables/supplier_payments_table.dart';
part 'tables/supplier_returns_table.dart';
part 'tables/supplier_ledger_table.dart';
part 'tables/user_activities_table.dart';
part 'tables/system_logs_table.dart';
part 'tables/inventory_transactions_table.dart';
part 'tables/expense_categories_table.dart';
part 'tables/expenses_table.dart';

// Generated code
part 'app_database.g.dart';

/// Main Drift database for the pharmacy application
@DriftDatabase(
  tables: [
    Products,
    ProductUnits,
    Sales,
    SaleItems,
    Suppliers,
    PurchaseOrders,
    PurchaseItems,
    CustomerDebts,
    DebtPayments,
    Users,
    UserSessions,
    SystemSettings,
    PharmacySettings,
    Notifications,
    Returns,
    ReturnItems,
    AuditLogs,
    SyncQueue,
    DailyPurchaseRequests,
    StockMovements,
    SupplierPayments,
    SupplierReturns,
    SupplierLedger,
    UserActivities,
    SystemLogs,
    InventoryTransactions,
    ExpenseCategories,
    Expenses,
  ],
  daos: [
    ProductDriftDao,
    SalesDriftDao,
    CustomerDebtDriftDao,
    DailyPurchaseRequestDriftDao,
    AuditLogDriftDao,
    ReturnDriftDao,
    SupplierDriftDao,
    SupplierReturnsDriftDao,
    PurchaseOrderDriftDao,
    SyncDriftDao,
    SettingsDriftDao,
    UsersDriftDao,
    InventoryTransactionDriftDao,
    NotificationDriftDao,
    SystemLogsDriftDao,
    ExpenseDriftDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3; // v3: Added expenses + expense_categories tables

  // ==========================================================================
  // Smart Integrity Check
  // ==========================================================================
  
  static DateTime? _lastIntegrityCheck;
  static const _integrityCheckInterval = Duration(hours: 24);
  
  /// ✅ فحص ذكي للـ Integrity - لا يحظر فتح القاعدة
  Future<void> _smartIntegrityCheck() async {
    final now = DateTime.now();
    
    // فحص فقط إذا لم يتم الفحص في الـ 24 ساعة الماضية
    if (_lastIntegrityCheck != null &&
        now.difference(_lastIntegrityCheck!) < _integrityCheckInterval) {
      print('⏭️ Skipping integrity check (checked recently)');
      return;
    }
    
    // ✅ فحص سريع فقط (quick_check)
    final quickResult = await customSelect('PRAGMA quick_check').getSingle();
    final quickCheckResult = quickResult.data['integrity_check'];
    
    if (quickCheckResult != 'ok') {
      print('⚠️ Quick check failed, running full integrity check...');
      
      // ✅ فحص كامل فقط إذا فشل الفحص السريع
      final fullResult = await customSelect('PRAGMA integrity_check').getSingle();
      final integrityResult = fullResult.data['integrity_check'];
      
      if (integrityResult != 'ok') {
        print('❌ Database integrity check failed: $integrityResult');
        throw Exception('Database integrity check failed: $integrityResult');
      }
    }
    
    _lastIntegrityCheck = now;
    print('✅ Database integrity check passed');
  }

  /// Initialize database by ensuring all tables exist
  /// Call this after creating AppDatabase to ensure tables are created
  Future<void> ensureInitialized() async {
    // This will trigger table creation if needed
    await customStatement('PRAGMA user_version');

    // Verify tables exist
    final tablesResult = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        .get();

    if (tablesResult.isEmpty) {
      print('⚠️ Tables not found, creating...');
      final migrator = Migrator(this);
      await migrator.createAll();
      print('✅ Tables created');
    } else {
      print('✅ Database tables already exist');
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          print('🆕 Creating database tables...');
          await m.createAll();
          print('✅ All tables created successfully');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          print('⬆️ Upgrading database from $from to $to');

          // Migration from v1 to v2: Add soft delete + audit trail + inventory transactions
          if (from == 1 && to == 2) {
            print(
                '📦 Running migration v1 → v2: Adding soft delete, audit trail, and inventory transactions');

            // Add soft delete columns to Products
            await customStatement(
                'ALTER TABLE products ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');
            await customStatement(
                'ALTER TABLE products ADD COLUMN deleted_at INTEGER');
            await customStatement(
                'ALTER TABLE products ADD COLUMN created_by TEXT');
            await customStatement(
                'ALTER TABLE products ADD COLUMN updated_by TEXT');

            // Add soft delete columns to Sales
            await customStatement(
                'ALTER TABLE sales ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');
            await customStatement(
                'ALTER TABLE sales ADD COLUMN deleted_at INTEGER');
            await customStatement(
                'ALTER TABLE sales ADD COLUMN updated_at INTEGER');
            await customStatement(
                'ALTER TABLE sales ADD COLUMN created_by TEXT');
            await customStatement(
                'ALTER TABLE sales ADD COLUMN updated_by TEXT');

            // Add soft delete columns to SaleItems
            await customStatement(
                'ALTER TABLE sale_items ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');
            await customStatement(
                'ALTER TABLE sale_items ADD COLUMN deleted_at INTEGER');
            await customStatement(
                'ALTER TABLE sale_items ADD COLUMN created_at INTEGER');
            await customStatement(
                'ALTER TABLE sale_items ADD COLUMN created_by TEXT');

            // Create InventoryTransactions table
            await customStatement('''
              CREATE TABLE IF NOT EXISTS inventory_transactions (
                id TEXT NOT NULL PRIMARY KEY,
                product_id TEXT NOT NULL REFERENCES products(id),
                type TEXT NOT NULL,
                quantity REAL NOT NULL,
                reference_id TEXT,
                reference_type TEXT,
                notes TEXT,
                created_by TEXT,
                created_at INTEGER NOT NULL
              )
            ''');

            // Create indexes for InventoryTransactions
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_inv_trans_product ON inventory_transactions(product_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_inv_trans_reference ON inventory_transactions(reference_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_inv_trans_created_at ON inventory_transactions(created_at)');

            print('✅ Migration v1 → v2 completed successfully');
          }

          // Migration from v2 to v3: Add expense tracking tables
          if (from <= 2 && to >= 3) {
            print('📦 Running migration → v3: Adding expense tracking');

            await customStatement('''
              CREATE TABLE IF NOT EXISTS expense_categories (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT NOT NULL DEFAULT '0xe1d5',
                color INTEGER NOT NULL DEFAULT ${0xFF5BA3A3},
                created_at INTEGER NOT NULL
              )
            ''');

            await customStatement('''
              CREATE TABLE IF NOT EXISTS expenses (
                id TEXT NOT NULL PRIMARY KEY,
                category_id TEXT NOT NULL REFERENCES expense_categories(id),
                amount REAL NOT NULL,
                date INTEGER NOT NULL,
                note TEXT,
                is_recurring INTEGER NOT NULL DEFAULT 0,
                recurring_day INTEGER,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');

            // Create indexes
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');

            // Seed default categories
            final uuid = const Uuid();
            final now = DateTime.now().millisecondsSinceEpoch;
            final defaults = [
              {'name': 'إيجار', 'icon': '0xe6b2', 'color': 0xFF5BA3A3},
              {'name': 'كهرباء وماء', 'icon': '0xe601', 'color': 0xFF2C5F8D},
              {'name': 'رواتب', 'icon': '0xe7ef', 'color': 0xFFF39C12},
              {'name': 'نواقص', 'icon': '0xe59a', 'color': 0xFFE74C3C},
              {'name': 'أخرى', 'icon': '0xe5d3', 'color': 0xFF95A5A6},
            ];
            for (final cat in defaults) {
              await customStatement(
                "INSERT OR IGNORE INTO expense_categories (id, name, icon, color, created_at) "
                "VALUES ('${uuid.v4()}', '${cat['name']}', '${cat['icon']}', ${cat['color']}, $now)",
              );
            }

            print('✅ Migration → v3 completed successfully');
          }
        },
        beforeOpen: (details) async {
          print('🔓 Opening database (version: ${details.versionNow})');
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
          
          // ✅ فحص ذكي: فقط إذا لم يتم الفحص مؤخراً
          await _smartIntegrityCheck();
        },
      );
}

/// Opens the database connection
/// 🔄 إدارة نظيفة لقاعدة البيانات - حذف القواعد القديمة وبدء نظيف
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();

    // 🗑️ حذف جميع قواعد البيانات القديمة (لحل مشكلة تنسيق التواريخ)
    // ⚠️ CRITICAL Fix: Do not automatically delete old databases.
    // This previously caused data loss for users upgrading from older versions.
    // Migration logic should be handled explicitly if needed.
    /*
    final oldDatabases = [
      'larapill.db',
      'larapill_drift.db',
      'larapill_v2.db',
      'larapill_pharmacy.db',
    ];

    for (final dbName in oldDatabases) {
      final oldFile = File(p.join(dbFolder.path, dbName));
      if (await oldFile.exists()) {
        try {
          // await oldFile.delete(); // DISABLED for safety
          print('ℹ️ Found old database: $dbName (preserved)');
        } catch (e) {
          print('⚠️ Error checking $dbName: $e');
        }
      }
    }
    */

    // 🆕 حذف ملفات WAL القديمة التي قد تسبب مشاكل
    final walFile = File(p.join(dbFolder.path, 'larapill_v3.db-wal'));
    final shmFile = File(p.join(dbFolder.path, 'larapill_v3.db-shm'));
    if (await walFile.exists()) {
      try {
        await walFile.delete();
        print('🗑️ Deleted WAL file');
      } catch (e) {
        print('⚠️ Could not delete WAL file: $e');
      }
    }
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
        print('🗑️ Deleted SHM file');
      } catch (e) {
        print('⚠️ Could not delete SHM file: $e');
      }
    }

    // 🆕 قاعدة بيانات جديدة بإصدار v3
    final file = File(p.join(dbFolder.path, 'larapill_v3.db'));
    print('📂 Using database: ${file.path}');

    // ✅ استخدام WAL mode للأداء الأمثل
    return NativeDatabase(
      file,
      setup: (database) {
        // ✅ WAL mode أسرع للقراءة والكتابة المتزامنة
        database.execute('PRAGMA journal_mode = WAL');
        // ✅ توازن بين الأداء والموثوقية
        database.execute('PRAGMA synchronous = NORMAL');
        // ✅ زيادة حجم الكاش
        database.execute('PRAGMA cache_size = 10000');
        // ✅ تخزين temp tables في الذاكرة
        database.execute('PRAGMA temp_store = MEMORY');
        // ✅ تحسين query planner
        database.execute('PRAGMA optimize');
        print('📂 Database opened with WAL mode (optimized)');
      },
    );
  });
}
