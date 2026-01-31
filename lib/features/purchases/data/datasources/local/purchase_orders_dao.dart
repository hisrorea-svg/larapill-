import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';

/// بند في فاتورة الشراء للحفظ
class PurchaseItemData {
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double bonus;
  final double unitPrice;
  final String? expiryDate;

  const PurchaseItemData({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.bonus,
    required this.unitPrice,
    this.expiryDate,
  });

  /// التكلفة لكل وحدة (مع البونص)
  double get costPerUnit {
    final totalUnits = quantity + bonus;
    if (totalUnits <= 0) return 0;
    return (unitPrice * quantity) / totalUnits;
  }

  /// إجمالي البند
  double get total => unitPrice * quantity;
}

/// DAO لطلبات الشراء
class PurchaseOrdersDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// إنشاء طلب شراء جديد (مسودة)
  Future<String> createDraftOrder({
    required String supplierId,
    required String invoiceNumber,
    required List<PurchaseItemData> items,
    required String createdBy,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final orderId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    // حساب الإجمالي
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);

    await db.transaction((txn) async {
      // 1. إنشاء طلب الشراء
      await txn.insert('purchase_orders', {
        'id': orderId,
        'order_number': invoiceNumber,
        'supplier_id': supplierId,
        'subtotal': subtotal,
        'discount': 0,
        'tax': 0,
        'total': subtotal,
        'status': 'draft', // مسودة
        'order_date': now,
        'notes': notes,
        'created_by': createdBy,
        'created_at': now,
        'updated_at': now,
      });

      // 2. إضافة البنود
      for (final item in items) {
        await txn.insert('purchase_items', {
          'id': const Uuid().v4(),
          'purchase_order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit': item.unit,
          'quantity': item.quantity,
          'received_quantity': item.quantity + item.bonus,
          'unit_price': item.unitPrice,
          'total': item.total,
          'bonus': item.bonus,
          'expiry_date': item.expiryDate,
          'created_at': now,
        });
      }
    });

    return orderId;
  }

  /// ترحيل طلب الشراء (تحويل من مسودة إلى posted)
  Future<void> postOrder(String orderId) async {
    final db = await _dbHelper.database;
    await db.update(
      'purchase_orders',
      {
        'status': 'posted',
        'posted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  /// جلب بنود طلب شراء
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'purchase_items',
      where: 'purchase_order_id = ?',
      whereArgs: [orderId],
    );
  }

  /// جلب طلب شراء بالـ ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// جلب طلبات الشراء المسودة
  Future<List<Map<String, dynamic>>> getDraftOrders() async {
    final db = await _dbHelper.database;
    return await db.query(
      'purchase_orders',
      where: 'status = ?',
      whereArgs: ['draft'],
      orderBy: 'created_at DESC',
    );
  }

  /// جلب طلبات الشراء المرحّلة
  Future<List<Map<String, dynamic>>> getPostedOrders({int limit = 50}) async {
    final db = await _dbHelper.database;
    return await db.query(
      'purchase_orders',
      where: 'status = ?',
      whereArgs: ['posted'],
      orderBy: 'posted_at DESC',
      limit: limit,
    );
  }

  /// جلب طلبات مورد معين
  Future<List<Map<String, dynamic>>> getSupplierOrders(
      String supplierId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'purchase_orders',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
  }

  /// حذف مسودة
  Future<void> deleteDraftOrder(String orderId) async {
    final db = await _dbHelper.database;

    // التحقق من أنها مسودة
    final order = await getOrderById(orderId);
    if (order == null || order['status'] != 'draft') {
      throw Exception('لا يمكن حذف طلب مرحّل');
    }

    await db.delete(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  /// تحديث مسودة
  Future<void> updateDraftOrder({
    required String orderId,
    required List<PurchaseItemData> items,
    String? invoiceNumber,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    // التحقق من أنها مسودة
    final order = await getOrderById(orderId);
    if (order == null || order['status'] != 'draft') {
      throw Exception('لا يمكن تعديل طلب مرحّل');
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);

    await db.transaction((txn) async {
      // تحديث الطلب
      await txn.update(
        'purchase_orders',
        {
          if (invoiceNumber != null) 'order_number': invoiceNumber,
          'subtotal': subtotal,
          'total': subtotal,
          'notes': notes,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      // حذف البنود القديمة
      await txn.delete(
        'purchase_items',
        where: 'purchase_order_id = ?',
        whereArgs: [orderId],
      );

      // إضافة البنود الجديدة
      for (final item in items) {
        await txn.insert('purchase_items', {
          'id': const Uuid().v4(),
          'purchase_order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit': item.unit,
          'quantity': item.quantity,
          'received_quantity': item.quantity + item.bonus,
          'unit_price': item.unitPrice,
          'total': item.total,
          'bonus': item.bonus,
          'expiry_date': item.expiryDate,
          'created_at': now,
        });
      }
    });
  }

  /// إحصائيات المشتريات
  Future<Map<String, dynamic>> getPurchaseStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = "status = 'posted'";
    List<dynamic> whereArgs = [];

    if (fromDate != null) {
      whereClause += ' AND posted_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      whereClause += ' AND posted_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as order_count,
        COALESCE(SUM(total), 0) as total_amount
      FROM purchase_orders
      WHERE $whereClause
    ''', whereArgs);

    return result.first;
  }
}
