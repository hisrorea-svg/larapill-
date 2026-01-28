import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// ✅ إزالة استيراد crypto القديم - لن نحتاجه
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
import '../core/services/password_hasher.dart'; // ✅ استيراد خدمة التشفير الجديدة

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // استخدام مسار ثابت في Windows بدلاً من المسار المؤقت
    String path;
    if (Platform.isWindows) {
      final appDataPath = Platform.environment['LOCALAPPDATA'];
      final dbDir = Directory(join(appDataPath!, 'larapill', 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      path = join(dbDir.path, 'larapill.db');
      developer.log('📂 مسار قاعدة البيانات: $path', name: 'DatabaseHelper');
    } else {
      path = join(await getDatabasesPath(), 'larapill.db');
    }

    return await openDatabase(
      path,
      version: 12, // ✅ النسخة 12: إضافة جدول الإشعارات
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ✅ إنشاء الجداول الأساسية + المستخدمين
  Future<void> _onCreate(Database db, int version) async {
    try {
      // جدول المنتجات ✅ مع is_active
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          scientific_name TEXT,
          company TEXT NOT NULL,
          category TEXT NOT NULL,
          barcode TEXT UNIQUE NOT NULL,
          expiry_date TEXT,
          production_date TEXT,
          base_unit TEXT NOT NULL,
          current_stock REAL DEFAULT 0,
          min_stock_level REAL DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          updated_at INTEGER DEFAULT 0
        )
      ''');

      // 🔔 جدول الإشعارات (للإنشاء الجديد)
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT NOT NULL,
          priority TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          action_data TEXT,
          user_id TEXT
        )
      ''');

      // فهرس الإشعارات
      await db.execute(
          'CREATE INDEX idx_notifications_is_read ON notifications(is_read)');
      await db.execute(
          'CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC)');

      // جدول وحدات المنتج والأسعار
      await db.execute('''
        CREATE TABLE product_units (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          unit TEXT NOT NULL,
          selling_price REAL NOT NULL,
          cost_price REAL NOT NULL,
          conversion_to_base REAL DEFAULT 1.0,
          description TEXT NOT NULL,
          quantity INTEGER,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
          UNIQUE(product_id, unit)
        )
      ''');

      // جدول الموردين
      await db.execute('''
        CREATE TABLE suppliers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          contact_person TEXT,
          phone TEXT,
          email TEXT,
          address TEXT,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // جدول طلبات الشراء
      await db.execute('''
        CREATE TABLE purchase_orders (
          id TEXT PRIMARY KEY,
          order_number TEXT UNIQUE NOT NULL,
          supplier_id TEXT NOT NULL,
          subtotal REAL DEFAULT 0.0,
          discount REAL DEFAULT 0.0,
          tax REAL DEFAULT 0.0,
          total REAL DEFAULT 0.0,
          status TEXT DEFAULT 'pending',
          order_date TEXT NOT NULL,
          expected_delivery_date TEXT,
          actual_delivery_date TEXT,
          notes TEXT,
          created_by TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
          FOREIGN KEY (created_by) REFERENCES users (id)
        )
      ''');

      // جدول عناصر طلبات الشراء
      await db.execute('''
        CREATE TABLE purchase_items (
          id TEXT PRIMARY KEY,
          purchase_order_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          unit TEXT NOT NULL,
          quantity REAL NOT NULL,
          received_quantity REAL DEFAULT 0.0,
          unit_price REAL NOT NULL,
          total REAL NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // 🛒 جدول طلبيات الشراء اليومية (مبسّط)
      await db.execute('''
        CREATE TABLE daily_purchase_requests (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          requested_quantity REAL NOT NULL,
          unit TEXT,
          auto_added INTEGER DEFAULT 0,
          supplier_name TEXT,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');

      // جدول المبيعات ✅ مع cashier_name وحقول الديون
      await db.execute('''
        CREATE TABLE sales (
          id TEXT PRIMARY KEY,
          invoice_number TEXT UNIQUE,
          date TEXT NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL DEFAULT 0,
          tax REAL DEFAULT 0,
          total REAL NOT NULL,
          paid_amount REAL NOT NULL DEFAULT 0,
          remaining_amount REAL NOT NULL DEFAULT 0,
          payment_status TEXT NOT NULL DEFAULT 'paid',
          payment_method TEXT NOT NULL,
          customer_name TEXT,
          customer_phone TEXT,
          cashier_id TEXT NOT NULL,
          cashier_name TEXT,
          status TEXT NOT NULL DEFAULT 'completed',
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (cashier_id) REFERENCES users (id)
        )
      ''');

      // جدول عناصر المبيعة
      await db.execute('''
        CREATE TABLE sale_items (
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          unit TEXT NOT NULL,
          unit_price REAL NOT NULL,
          quantity REAL NOT NULL,
          total REAL NOT NULL,
          batch_number TEXT,
          expiry_date TEXT,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // 💰 جدول ديون العملاء
      await db.execute('''
        CREATE TABLE customer_debts (
          id TEXT PRIMARY KEY,
          customer_name TEXT NOT NULL,
          customer_phone TEXT,
          total_debt REAL NOT NULL DEFAULT 0,
          total_paid REAL NOT NULL DEFAULT 0,
          remaining_debt REAL NOT NULL DEFAULT 0,
          sales_count INTEGER NOT NULL DEFAULT 0,
          last_transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 💳 جدول دفعات تسديد الديون
      await db.execute('''
        CREATE TABLE debt_payments (
          id TEXT PRIMARY KEY,
          customer_debt_id TEXT NOT NULL,
          sale_id TEXT,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          payment_date TEXT NOT NULL,
          cashier_id TEXT NOT NULL,
          cashier_name TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_debt_id) REFERENCES customer_debts (id) ON DELETE CASCADE,
          FOREIGN KEY (sale_id) REFERENCES sales (id),
          FOREIGN KEY (cashier_id) REFERENCES users (id)
        )
      ''');

      // 🆕 جدول إعدادات النظام
      await db.execute('''
        CREATE TABLE system_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          description TEXT,
          category TEXT DEFAULT 'general',
          updated_at TEXT NOT NULL
        )
      ''');

      // 👥 جدول المستخدمين
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'cashier',
          permissions TEXT,
          is_active INTEGER DEFAULT 1,
          force_password_change INTEGER DEFAULT 0,
          last_login TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          created_by TEXT
        )
      ''');

      // 🔐 جدول جلسات المستخدمين
      await db.execute('''
        CREATE TABLE user_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          session_token TEXT UNIQUE NOT NULL,
          device_info TEXT,
          ip_address TEXT,
          login_time TEXT NOT NULL,
          last_activity TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // 📋 جدول سجل العمليات
      await db.execute('''
        CREATE TABLE user_activities (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          ip_address TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // 📝 جدول سجل النظام
      await db.execute('''
        CREATE TABLE system_logs (
          id TEXT PRIMARY KEY,
          level TEXT NOT NULL,
          message TEXT NOT NULL,
          details TEXT,
          user_id TEXT,
          module TEXT,
          action TEXT,
          ip_address TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // 📊 جدول سجل التدقيق (Audit Logs)
      await db.execute('''
        CREATE TABLE audit_logs (
          id TEXT PRIMARY KEY,
          action_type TEXT NOT NULL,
          action_name TEXT NOT NULL,
          severity TEXT NOT NULL,
          user_id TEXT NOT NULL,
          user_name TEXT,
          entity_type TEXT,
          entity_id TEXT,
          description TEXT,
          metadata TEXT,
          ip_address TEXT,
          is_success INTEGER DEFAULT 1,
          error_message TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // جدول المرتجعات
      await db.execute('''
        CREATE TABLE returns (
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          return_date TEXT NOT NULL,
          reason TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          total_refund REAL NOT NULL,
          refund_method TEXT NOT NULL,
          notes TEXT,
          processed_by TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id),
          FOREIGN KEY (processed_by) REFERENCES users (id)
        )
      ''');

      // جدول عناصر المرتجعات
      await db.execute('''
        CREATE TABLE return_items (
          id TEXT PRIMARY KEY,
          return_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          unit TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit_price REAL NOT NULL,
          total REAL NOT NULL,
          reason_details TEXT,
          batch_number TEXT,
          expiry_date TEXT,
          FOREIGN KEY (return_id) REFERENCES returns (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // جدول إعدادات الصيدلية
      await db.execute('''
        CREATE TABLE pharmacy_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name_ar TEXT NOT NULL,
          name_en TEXT,
          license_number TEXT,
          phone TEXT,
          mobile TEXT,
          email TEXT,
          website TEXT,
          address TEXT,
          city TEXT,
          tax_number TEXT,
          commercial_registration TEXT,
          logo_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 🔌 جدول إعدادات الـ Terminal
      await db.execute('''
        CREATE TABLE terminal_config (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // 🔌 جدول قائمة المزامنة (المبيعات المعلّقة)
      await db.execute('''
        CREATE TABLE sync_queue (
          id TEXT PRIMARY KEY,
          action TEXT NOT NULL,
          payload TEXT NOT NULL,
          status INTEGER DEFAULT 0,
          retry_count INTEGER DEFAULT 0,
          error_message TEXT,
          created_at INTEGER NOT NULL,
          last_attempt_at INTEGER
        )
      ''');

      // فهارس لتحسين الأداء
      final indexes = [
        // فهارس المنتجات
        'CREATE INDEX idx_products_barcode ON products (barcode)',
        'CREATE INDEX idx_products_category ON products (category)',
        'CREATE INDEX idx_products_active ON products (is_active)',
        'CREATE INDEX idx_products_expiry ON products (expiry_date)',
        'CREATE INDEX idx_product_units_product_id ON product_units (product_id)',

        // فهارس المبيعات
        'CREATE INDEX idx_sales_date ON sales (date)',
        'CREATE INDEX idx_sales_status ON sales (status)',
        'CREATE INDEX idx_sales_customer ON sales (customer_phone)',
        'CREATE INDEX idx_sales_cashier ON sales (cashier_id)',
        'CREATE INDEX idx_sales_payment_status ON sales (payment_status)',
        'CREATE INDEX idx_sale_items_sale_id ON sale_items (sale_id)',
        'CREATE INDEX idx_sale_items_product_id ON sale_items (product_id)',

        // فهارس المشتريات
        'CREATE INDEX idx_purchase_orders_status ON purchase_orders (status)',
        'CREATE INDEX idx_purchase_orders_date ON purchase_orders (order_date)',
        'CREATE INDEX idx_purchase_orders_created_by ON purchase_orders (created_by)',
        'CREATE INDEX idx_purchase_items_order_id ON purchase_items (purchase_order_id)',

        // فهارس المستخدمين
        'CREATE INDEX idx_users_username ON users (username)',
        'CREATE INDEX idx_users_role ON users (role)',
        'CREATE INDEX idx_users_active ON users (is_active)',
        'CREATE INDEX idx_user_sessions_user_id ON user_sessions (user_id)',
        'CREATE INDEX idx_user_sessions_active ON user_sessions (is_active)',

        // فهارس سجل التدقيق
        'CREATE INDEX idx_audit_logs_user_id ON audit_logs (user_id)',
        'CREATE INDEX idx_audit_logs_action_type ON audit_logs (action_type)',
        'CREATE INDEX idx_audit_logs_severity ON audit_logs (severity)',
        'CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id)',
        'CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at)',
        'CREATE INDEX idx_user_activities_user_id ON user_activities (user_id)',
        'CREATE INDEX idx_user_activities_action ON user_activities (action)',

        // فهارس سجل النظام
        'CREATE INDEX idx_system_logs_level ON system_logs (level)',
        'CREATE INDEX idx_system_logs_created_at ON system_logs (created_at)',
        'CREATE INDEX idx_system_logs_user_id ON system_logs (user_id)',
        'CREATE INDEX idx_system_logs_module ON system_logs (module)',

        // فهارس المرتجعات
        'CREATE INDEX idx_returns_sale_id ON returns (sale_id)',
        'CREATE INDEX idx_returns_date ON returns (return_date)',
        'CREATE INDEX idx_returns_status ON returns (status)',
        'CREATE INDEX idx_return_items_return_id ON return_items (return_id)',
        'CREATE INDEX idx_return_items_product_id ON return_items (product_id)',

        // 💰 فهارس الديون
        'CREATE INDEX idx_customer_debts_phone ON customer_debts (customer_phone)',
        'CREATE INDEX idx_customer_debts_remaining ON customer_debts (remaining_debt)',
        'CREATE INDEX idx_debt_payments_customer ON debt_payments (customer_debt_id)',
        'CREATE INDEX idx_debt_payments_date ON debt_payments (payment_date)',

        // 🔌 فهارس المزامنة
        'CREATE INDEX idx_sync_queue_status ON sync_queue (status)',
        'CREATE INDEX idx_sync_queue_created ON sync_queue (created_at)',
      ];

      for (final index in indexes) {
        await db.execute(index);
      }

      developer.log(
          '✅ قاعدة البيانات تم إنشاؤها بنجاح مع ${indexes.length} فهرس',
          name: 'DatabaseHelper');

      // إدراج الإعدادات الافتراضية
      await _insertDefaultSettings(db);

      // إدراج البيانات الافتراضية
      await insertDefaultData(db);

      // إضافة المستخدم الافتراضي
      await _insertDefaultUser(db);

      // إضافة بيانات الصيدلية الافتراضية
      await _insertDefaultPharmacySettings(db);
    } catch (e) {
      developer.log('❌ خطأ في إنشاء قاعدة البيانات: $e',
          name: 'DatabaseHelper');
      rethrow;
    }
  }

  // ✅ Migration: ترقية قاعدة البيانات
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('🔄 ترقية قاعدة البيانات من $oldVersion إلى $newVersion',
        name: 'DatabaseHelper');

    // إضافة عمود cashier_name إذا كانت النسخة أقدم من 2
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN cashier_name TEXT');
        developer.log('✅ تم إضافة عمود cashier_name لجدول sales',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('⚠️ العمود cashier_name موجود مسبقاً أو حدث خطأ: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة نظام المرتجعات في النسخة 3
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE returns (
            id TEXT PRIMARY KEY,
            sale_id TEXT NOT NULL,
            return_date TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            total_refund REAL NOT NULL,
            refund_method TEXT NOT NULL,
            notes TEXT,
            processed_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales (id),
            FOREIGN KEY (processed_by) REFERENCES users (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE return_items (
            id TEXT PRIMARY KEY,
            return_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            unit TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            total REAL NOT NULL,
            reason_details TEXT,
            batch_number TEXT,
            expiry_date TEXT,
            FOREIGN KEY (return_id) REFERENCES returns (id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products (id)
          )
        ''');

        await db
            .execute('CREATE INDEX idx_returns_sale_id ON returns (sale_id)');
        await db
            .execute('CREATE INDEX idx_returns_date ON returns (return_date)');
        await db.execute('CREATE INDEX idx_returns_status ON returns (status)');
        await db.execute(
            'CREATE INDEX idx_return_items_return_id ON return_items (return_id)');
        await db.execute(
            'CREATE INDEX idx_return_items_product_id ON return_items (product_id)');

        developer.log('✅ تم إضافة نظام المرتجعات بنجاح',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة نظام المرتجعات: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة حقل force_password_change للمستخدمين الموجودين
    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE users ADD COLUMN force_password_change INTEGER DEFAULT 0
        ''');

        // تحديث المستخدم الافتراضي لإجبار تغيير كلمة المرور
        await db.execute('''
          UPDATE users SET force_password_change = 1 WHERE username = 'admin'
        ''');

        developer.log('✅ تم إضافة حقل force_password_change بنجاح',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة حقل force_password_change: $e',
            name: 'DatabaseHelper');
      }

      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN is_active INTEGER DEFAULT 1');
        developer.log('✅ تم إضافة عمود is_active لجدول products',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('⚠️ العمود is_active موجود مسبقاً أو حدث خطأ: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة جدول pharmacy_settings في النسخة 5
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE pharmacy_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name_ar TEXT NOT NULL,
            name_en TEXT,
            license_number TEXT,
            phone TEXT,
            mobile TEXT,
            email TEXT,
            website TEXT,
            address TEXT,
            city TEXT,
            tax_number TEXT,
            commercial_registration TEXT,
            logo_path TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        developer.log('✅ تم إضافة جدول pharmacy_settings بنجاح',
            name: 'DatabaseHelper');

        // إضافة البيانات الافتراضية
        await _insertDefaultPharmacySettings(db);
      } catch (e) {
        developer.log('❌ خطأ في إضافة جدول pharmacy_settings: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة جدول system_logs في النسخة 6
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE system_logs (
            id TEXT PRIMARY KEY,
            level TEXT NOT NULL,
            message TEXT NOT NULL,
            details TEXT,
            user_id TEXT,
            module TEXT,
            action TEXT,
            ip_address TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // إضافة الفهارس
        await db.execute(
            'CREATE INDEX idx_system_logs_level ON system_logs (level)');
        await db.execute(
            'CREATE INDEX idx_system_logs_created_at ON system_logs (created_at)');
        await db.execute(
            'CREATE INDEX idx_system_logs_user_id ON system_logs (user_id)');
        await db.execute(
            'CREATE INDEX idx_system_logs_module ON system_logs (module)');

        developer.log('✅ تم إضافة جدول system_logs بنجاح',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة جدول system_logs: $e',
            name: 'DatabaseHelper');
      }
    }

    // 💰 إضافة نظام الديون في النسخة 7
    if (oldVersion < 7) {
      try {
        // إضافة حقول الديون لجدول sales
        await db.execute(
            'ALTER TABLE sales ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0');
        await db.execute(
            'ALTER TABLE sales ADD COLUMN remaining_amount REAL NOT NULL DEFAULT 0');
        await db.execute(
            'ALTER TABLE sales ADD COLUMN payment_status TEXT NOT NULL DEFAULT \'paid\'');

        // تحديث البيانات الموجودة: المبيعات القديمة كلها مدفوعة
        await db.execute('''
          UPDATE sales 
          SET paid_amount = total, 
              remaining_amount = 0, 
              payment_status = 'paid' 
          WHERE paid_amount = 0
        ''');

        // إنشاء جدول ديون العملاء
        await db.execute('''
          CREATE TABLE customer_debts (
            id TEXT PRIMARY KEY,
            customer_name TEXT NOT NULL,
            customer_phone TEXT,
            total_debt REAL NOT NULL DEFAULT 0,
            total_paid REAL NOT NULL DEFAULT 0,
            remaining_debt REAL NOT NULL DEFAULT 0,
            sales_count INTEGER NOT NULL DEFAULT 0,
            last_transaction_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // إنشاء جدول دفعات تسديد الديون
        await db.execute('''
          CREATE TABLE debt_payments (
            id TEXT PRIMARY KEY,
            customer_debt_id TEXT NOT NULL,
            sale_id TEXT,
            amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            payment_date TEXT NOT NULL,
            cashier_id TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (customer_debt_id) REFERENCES customer_debts (id) ON DELETE CASCADE,
            FOREIGN KEY (sale_id) REFERENCES sales (id),
            FOREIGN KEY (cashier_id) REFERENCES users (id)
          )
        ''');

        // إضافة فهارس للأداء
        await db.execute(
            'CREATE INDEX idx_sales_payment_status ON sales (payment_status)');
        await db.execute(
            'CREATE INDEX idx_customer_debts_phone ON customer_debts (customer_phone)');
        await db.execute(
            'CREATE INDEX idx_customer_debts_remaining ON customer_debts (remaining_debt)');
        await db.execute(
            'CREATE INDEX idx_debt_payments_customer ON debt_payments (customer_debt_id)');
        await db.execute(
            'CREATE INDEX idx_debt_payments_date ON debt_payments (payment_date)');

        developer.log('✅ تم إضافة نظام الديون بنجاح (النسخة 7)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة نظام الديون: $e', name: 'DatabaseHelper');
      }
    }

    // إضافة طلبيات الشراء اليومية في النسخة 8
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE daily_purchase_requests (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            requested_quantity REAL NOT NULL,
            auto_added INTEGER DEFAULT 0,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
          )
        ''');

        // إضافة فهارس للأداء
        await db.execute(
            'CREATE INDEX idx_daily_purchase_requests_date ON daily_purchase_requests (date)');
        await db.execute(
            'CREATE INDEX idx_daily_purchase_requests_product ON daily_purchase_requests (product_id)');
        await db.execute(
            'CREATE INDEX idx_daily_purchase_requests_auto ON daily_purchase_requests (auto_added)');

        developer.log('✅ تم إضافة طلبيات الشراء اليومية بنجاح (النسخة 8)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة طلبيات الشراء اليومية: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة حقل اسم المورد في النسخة 9
    if (oldVersion < 9) {
      try {
        await db.execute('''
          ALTER TABLE daily_purchase_requests 
          ADD COLUMN supplier_name TEXT
        ''');

        developer.log('✅ تم إضافة حقل اسم المورد للطلبيات اليومية (النسخة 9)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة حقل اسم المورد: $e',
            name: 'DatabaseHelper');
      }
    }

    // إضافة حقل الوحدة في النسخة 10
    if (oldVersion < 10) {
      try {
        await db.execute('''
          ALTER TABLE daily_purchase_requests 
          ADD COLUMN unit TEXT
        ''');

        developer.log('✅ تم إضافة حقل الوحدة للطلبيات اليومية (النسخة 10)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة حقل الوحدة: $e', name: 'DatabaseHelper');
      }
    }

    // 🔌 إضافة جداول المزامنة في النسخة 11
    if (oldVersion < 11) {
      try {
        // جدول إعدادات الـ Terminal
        await db.execute('''
          CREATE TABLE IF NOT EXISTS terminal_config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // جدول قائمة المزامنة (المبيعات المعلّقة)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_queue (
            id TEXT PRIMARY KEY,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            status INTEGER DEFAULT 0,
            retry_count INTEGER DEFAULT 0,
            error_message TEXT,
            created_at INTEGER NOT NULL,
            last_attempt_at INTEGER
          )
        ''');

        // إضافة حقل updated_at للمنتجات
        try {
          await db.execute(
              'ALTER TABLE products ADD COLUMN updated_at INTEGER DEFAULT 0');
        } catch (_) {
          // الحقل موجود مسبقاً
        }

        // إضافة فهارس للمزامنة
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (status)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue (created_at)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_products_updated_at ON products (updated_at)');

        developer.log('✅ تم إضافة جداول المزامنة بنجاح (النسخة 11)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة جداول المزامنة: $e',
            name: 'DatabaseHelper');
      }
    }

    // 🔔 إضافة جدول الإشعارات في النسخة 12
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            type TEXT NOT NULL,
            priority TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            action_data TEXT,
            user_id TEXT
          )
        ''');

        // إضافة فهارس الإشعارات
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC)');

        developer.log('✅ تم إضافة جدول الإشعارات بنجاح (النسخة 12)',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('❌ خطأ في إضافة جدول الإشعارات: $e',
            name: 'DatabaseHelper');
      }
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final settings = [
      {
        'key': 'pharmacy_name',
        'value': '',
        'description': 'اسم الصيدلية',
        'category': 'general'
      },
      {
        'key': 'pharmacy_name_en',
        'value': '',
        'description': 'اسم الصيدلية بالإنجليزية',
        'category': 'general'
      },
      {
        'key': 'pharmacy_address',
        'value': '',
        'description': 'عنوان الصيدلية',
        'category': 'general'
      },
      {
        'key': 'pharmacy_phone',
        'value': '',
        'description': 'هاتف الصيدلية',
        'category': 'general'
      },
      {
        'key': 'pharmacy_email',
        'value': '',
        'description': 'بريد الصيدلية الإلكتروني',
        'category': 'general'
      },
      {
        'key': 'pharmacy_license',
        'value': '',
        'description': 'رقم ترخيص الصيدلية',
        'category': 'general'
      },
      {
        'key': 'pharmacy_owner',
        'value': '',
        'description': 'اسم مالك الصيدلية',
        'category': 'general'
      },
      {
        'key': 'tax_rate',
        'value': '0.0',
        'description': 'معدل الضريبة',
        'category': 'financial'
      },
      {
        'key': 'currency',
        'value': 'IQD',
        'description': 'العملة',
        'category': 'financial'
      },
      {
        'key': 'invoice_prefix',
        'value': 'INV',
        'description': 'بادئة رقم الفاتورة',
        'category': 'sales'
      },
      {
        'key': 'expiry_alert_days',
        'value': '30',
        'description': 'أيام تنبيه انتهاء الصلاحية',
        'category': 'alerts'
      },
      {
        'key': 'low_stock_alert',
        'value': 'true',
        'description': 'تنبيه المخزون المنخفض',
        'category': 'alerts'
      },
    ];

    for (final setting in settings) {
      await db.insert('system_settings', {
        ...setting,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    developer.log('✅ تم إدراج الإعدادات الافتراضية (فارغة)',
        name: 'DatabaseHelper');
  }

  Future<void> insertDefaultData(Database db) async {
    try {
      final userCount =
          await db.rawQuery('SELECT COUNT(*) as count FROM users');
      if ((userCount.first['count'] as int) > 0) {
        developer.log('المستخدم الافتراضي موجود مسبقاً',
            name: 'DatabaseHelper');
        return;
      }

      developer.log('✅ لا توجد بيانات تجريبية - قاعدة بيانات نظيفة',
          name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في فحص البيانات: $e', name: 'DatabaseHelper');
    }
  }

  // ✅ إنشاء المستخدم الافتراضي بكلمة مرور قوية وإجبار تغيير
  Future<void> _insertDefaultUser(Database db) async {
    try {
      // فحص وجود المستخدم الافتراضي
      final existingUsers =
          await db.query('users', where: 'username = ?', whereArgs: ['admin']);

      if (existingUsers.isNotEmpty) {
        developer.log('ℹ️ المستخدم الافتراضي موجود بالفعل',
            name: 'DatabaseHelper');
        return;
      }

      // كلمة مرور قوية عشوائية (سيتم إجبار المستخدم على تغييرها)
      const temporaryStrongPassword = 'LaRaPill@2025!Admin#Temp';

      final defaultUser = {
        'id': 'admin-default',
        'username': 'admin',
        'full_name': 'مدير النظام',
        'email': null,
        'phone': null,
        'password_hash': PasswordHasher.hash(temporaryStrongPassword),
        'role': 'admin',
        'permissions': 'all',
        'is_active': 1,
        'force_password_change': 1, // ✅ إجبار تغيير كلمة المرور
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_by': 'system'
      };

      await db.insert('users', defaultUser);

      // تسجيل مع كلمة المرور المؤقتة (فقط مرة واحدة)
      developer.log('🔐 تم إنشاء المستخدم الافتراضي بكلمة مرور مؤقتة قوية',
          name: 'DatabaseHelper');
      developer.log('📝 اسم المستخدم: admin', name: 'DatabaseHelper');
      developer.log('🔑 كلمة المرور المؤقتة: $temporaryStrongPassword',
          name: 'DatabaseHelper');
      developer.log('⚠️ يجب تغيير كلمة المرور فور تسجيل الدخول الأول',
          name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في إنشاء المستخدم الافتراضي: $e',
          name: 'DatabaseHelper');
    }
  }

  // إدراج بيانات الصيدلية الافتراضية
  Future<void> _insertDefaultPharmacySettings(Database db) async {
    try {
      // فحص وجود بيانات الصيدلية
      final existing = await db.query('pharmacy_settings', limit: 1);

      if (existing.isNotEmpty) {
        developer.log('ℹ️ بيانات الصيدلية موجودة بالفعل',
            name: 'DatabaseHelper');
        return;
      }

      final defaultPharmacy = {
        'name_ar': 'صيدلية فارماكليك',
        'name_en': 'LaRaPill Pharmacy',
        'license_number': '',
        'phone': '',
        'mobile': '',
        'email': '',
        'website': '',
        'address': '',
        'city': '',
        'tax_number': '',
        'commercial_registration': '',
        'logo_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await db.insert('pharmacy_settings', defaultPharmacy);

      developer.log('✅ تم إدراج بيانات الصيدلية الافتراضية',
          name: 'DatabaseHelper');
      developer.log('🏥 اسم الصيدلية: صيدلية فارماكليك',
          name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في إدراج بيانات الصيدلية الافتراضية: $e',
          name: 'DatabaseHelper');
    }
  }

  Future<void> _createMissingTablesIfNeeded() async {
    final db = await database;

    try {
      await _createSystemSettingsIfMissing(db);
      await _createUserTablesIfMissing(db);
    } catch (e) {
      developer.log('❌ خطأ في إنشاء الجداول المفقودة: $e',
          name: 'DatabaseHelper');
    }
  }

  Future<void> _createSystemSettingsIfMissing(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='system_settings'");

    if (tables.isEmpty) {
      developer.log('🔧 إنشاء جدول system_settings المفقود...',
          name: 'DatabaseHelper');

      await db.execute('''
        CREATE TABLE system_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          description TEXT,
          category TEXT DEFAULT 'general',
          updated_at TEXT NOT NULL
        )
      ''');

      await _insertDefaultSettings(db);
      developer.log('✅ تم إنشاء جدول system_settings بنجاح',
          name: 'DatabaseHelper');
    }
  }

  Future<void> _createUserTablesIfMissing(Database db) async {
    final userTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");

    if (userTables.isEmpty) {
      developer.log('🔧 إنشاء جداول المستخدمين المفقودة...',
          name: 'DatabaseHelper');

      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'cashier',
          permissions TEXT,
          is_active INTEGER DEFAULT 1,
          last_login TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          created_by TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE user_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          session_token TEXT UNIQUE NOT NULL,
          device_info TEXT,
          ip_address TEXT,
          login_time TEXT NOT NULL,
          last_activity TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE user_activities (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          ip_address TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      final userIndexes = [
        'CREATE INDEX idx_users_username ON users (username)',
        'CREATE INDEX idx_users_role ON users (role)',
        'CREATE INDEX idx_users_active ON users (is_active)',
        'CREATE INDEX idx_user_sessions_user_id ON user_sessions (user_id)',
        'CREATE INDEX idx_user_sessions_active ON user_sessions (is_active)',
        'CREATE INDEX idx_user_activities_user_id ON user_activities (user_id)',
        'CREATE INDEX idx_user_activities_action ON user_activities (action)',
      ];

      for (final index in userIndexes) {
        await db.execute(index);
      }

      await _insertDefaultUser(db);

      developer.log('✅ تم إنشاء جداول المستخدمين بنجاح',
          name: 'DatabaseHelper');
    }
  }

  Future<void> initializeDatabase() async {
    try {
      await database;
      await _createMissingTablesIfNeeded();
      developer.log('✅ تم تهيئة قاعدة البيانات بنجاح', name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في تهيئة قاعدة البيانات: $e',
          name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    try {
      final queries = [
        'SELECT COUNT(*) as count FROM products',
        'SELECT COUNT(*) as count FROM sales WHERE status = "completed"',
        'SELECT COUNT(*) as count FROM suppliers WHERE is_active = 1',
        'SELECT COUNT(*) as count FROM purchase_orders',
        'SELECT COUNT(*) as count FROM users WHERE is_active = 1',
      ];

      final results =
          await Future.wait(queries.map((query) => db.rawQuery(query)));

      return {
        'products': (results[0].first['count'] as int),
        'sales': (results[1].first['count'] as int),
        'suppliers': (results[2].first['count'] as int),
        'purchase_orders': (results[3].first['count'] as int),
        'users': (results[4].first['count'] as int),
      };
    } catch (e) {
      developer.log('❌ خطأ في جلب إحصائيات قاعدة البيانات: $e',
          name: 'DatabaseHelper');
      return {
        'products': 0,
        'sales': 0,
        'suppliers': 0,
        'purchase_orders': 0,
        'users': 0,
      };
    }
  }

  Future<Map<String, dynamic>> createBackup() async {
    try {
      final db = await database;
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'larapill_backup_$timestamp.db';
      final backupPath = '${backupDir.path}/$fileName';

      final dbPath = db.path;
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      await dbFile.copy(backupPath);

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('فشل في إنشاء ملف النسخة الاحتياطية');
      }

      final fileSize = await backupFile.length();

      developer.log(
          '✅ تم إنشاء نسخة احتياطية: $fileName (${(fileSize / 1024).toStringAsFixed(1)} KB)',
          name: 'Backup');

      return {
        'success': true,
        'path': backupPath,
        'fileName': fileName,
        'size': fileSize,
        'date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ خطأ في إنشاء نسخة احتياطية: $e', name: 'Backup');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getBackupsList() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        final stat = await file.stat();
        final fileName = file.path.split('/').last.split('\\').last;

        backups.add({
          'id': fileName.replaceAll('.db', ''),
          'file_name': fileName,
          'file_path': file.path,
          'backup_size': stat.size,
          'created_at': stat.modified.toIso8601String(),
          'status': 'completed',
        });
      }

      backups.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));

      return backups;
    } catch (e) {
      developer.log('❌ خطأ في جلب قائمة النسخ الاحتياطية: $e', name: 'Backup');
      return [];
    }
  }

  Future<Map<String, dynamic>> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return {
          'success': false,
          'error': 'ملف النسخة الاحتياطية غير موجود',
        };
      }

      try {
        final testDb = await openDatabase(backupPath, readOnly: true);
        final testResult = await testDb.rawQuery('PRAGMA integrity_check');
        await testDb.close();

        if (testResult.first.values.first != 'ok') {
          return {
            'success': false,
            'error': 'ملف النسخة الاحتياطية تالف',
          };
        }
      } catch (e) {
        return {
          'success': false,
          'error': 'ملف النسخة الاحتياطية غير صالح',
        };
      }

      await close();

      final dbPath = join(await getDatabasesPath(), 'larapill.db');
      await backupFile.copy(dbPath);

      _database = null;
      await database;

      developer.log('✅ تم استعادة النسخة الاحتياطية بنجاح', name: 'Backup');

      return {
        'success': true,
        'message': 'تم استعادة النسخة الاحتياطية بنجاح',
      };
    } catch (e) {
      developer.log('❌ خطأ في استعادة النسخة الاحتياطية: $e', name: 'Backup');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> deleteBackup(String backupId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDir.path}/backups/$backupId.db';
      final file = File(backupPath);

      if (await file.exists()) {
        await file.delete();
        developer.log('✅ تم حذف النسخة الاحتياطية: $backupId', name: 'Backup');
        return true;
      }

      return false;
    } catch (e) {
      developer.log('❌ خطأ في حذف النسخة الاحتياطية: $e', name: 'Backup');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getExpiringProducts(
      {int daysAhead = 30}) async {
    try {
      final db = await database;
      final futureDate = DateTime.now().add(Duration(days: daysAhead));

      return await db.rawQuery('''
        SELECT p.*, pu.selling_price 
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.conversion_to_base = 1.0
        WHERE p.expiry_date IS NOT NULL 
        AND p.expiry_date <= ? 
        AND p.expiry_date > ?
        AND p.is_active = 1
        ORDER BY p.expiry_date ASC
      ''', [futureDate.toIso8601String(), DateTime.now().toIso8601String()]);
    } catch (e) {
      developer.log('❌ خطأ في جلب المنتجات منتهية الصلاحية: $e',
          name: 'DatabaseHelper');
      return [];
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final result = await db.query(
        'system_settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      return result.isEmpty ? null : result.first['value'] as String;
    } catch (e) {
      developer.log('❌ خطأ في جلب الإعداد: $e', name: 'DatabaseHelper');
      return null;
    }
  }

  Future<bool> setSetting(String key, String value,
      {String? description, String? category}) async {
    try {
      final db = await database;
      await db.insert(
        'system_settings',
        {
          'key': key,
          'value': value,
          'description': description,
          'category': category ?? 'general',
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return true;
    } catch (e) {
      developer.log('❌ خطأ في حفظ الإعداد: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  Future<Map<String, dynamic>> exportData() async {
    try {
      final db = await database;

      final tables = [
        'products',
        'product_units',
        'suppliers',
        'sales',
        'sale_items',
        'purchase_orders',
        'purchase_items',
        'system_settings',
      ];

      final exportData = <String, dynamic>{
        'export_info': {
          'date': DateTime.now().toIso8601String(),
          'version': '1.0',
          'pharmacy_name': await getSetting('pharmacy_name'),
          'tables_count': tables.length,
        }
      };

      int totalRecords = 0;

      for (final table in tables) {
        try {
          final data = await db.query(table);
          exportData[table] = data;
          totalRecords += data.length;
        } catch (e) {
          exportData[table] = [];
        }
      }

      exportData['export_info']['total_records'] = totalRecords;

      developer.log(
          '✅ تم تصدير البيانات: $totalRecords سجل من ${tables.length} جدول',
          name: 'Export');
      return exportData;
    } catch (e) {
      developer.log('❌ خطأ في تصدير البيانات: $e', name: 'Export');
      return {};
    }
  }

  Future<void> cleanupOldData() async {
    final db = await database;
    try {
      final deletedSales = await db.delete(
        'sales',
        where: 'status = ? AND created_at < ?',
        whereArgs: [
          'cancelled',
          DateTime.now().subtract(const Duration(days: 90)).toIso8601String()
        ],
      );

      final deletedSessions = await db.delete(
        'user_sessions',
        where: 'is_active = 0 AND last_activity < ?',
        whereArgs: [
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String()
        ],
      );

      developer.log(
          '✅ تم تنظيف البيانات: $deletedSales مبيعة ملغاة، $deletedSessions جلسة منتهية',
          name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في تنظيف البيانات: $e', name: 'DatabaseHelper');
    }
  }

  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.first.values.first == 'ok';

      developer.log(
          'فحص سلامة قاعدة البيانات: ${isOk ? "سليمة ✅" : "تحتاج إصلاح ⚠️"}',
          name: 'DatabaseHelper');
      return isOk;
    } catch (e) {
      developer.log('❌ خطأ في فحص قاعدة البيانات: $e', name: 'DatabaseHelper');
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'larapill.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      developer.log('✅ تم حذف قاعدة البيانات', name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في حذف قاعدة البيانات: $e', name: 'DatabaseHelper');
    }
  }

  Future<void> recreateDatabase() async {
    try {
      await deleteDatabase();
      _database = null;
      await database;
      developer.log('✅ تم إعادة إنشاء قاعدة البيانات بنجاح',
          name: 'DatabaseHelper');
    } catch (e) {
      developer.log('❌ خطأ في إعادة إنشاء قاعدة البيانات: $e',
          name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      developer.log('✅ تم إغلاق قاعدة البيانات', name: 'DatabaseHelper');
    }
  }
}
