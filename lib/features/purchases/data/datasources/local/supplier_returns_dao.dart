import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';
import '../../models/supplier_return.dart';
import 'stock_movements_dao.dart';
import 'supplier_ledger_dao.dart';

/// DAO لمرتجعات الموردين
class SupplierReturnsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StockMovementsDao _stockDao = StockMovementsDao();
  final SupplierLedgerDao _ledgerDao = SupplierLedgerDao();

  /// إضافة مرتجع جديد
  Future<String> createReturn({
    required String supplierId,
    String? invoiceId,
    required String productId,
    required String productName,
    required double quantity,
    required double amount,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();

    await db.insert('supplier_returns', {
      'id': id,
      'supplier_id': supplierId,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'amount': amount,
      'status': 'prepared',
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });

    return id;
  }

  /// تسليم المرتجع للمورد (يخصم من المخزون + يقلل الدين)
  Future<void> deliverReturn(String returnId) async {
    final db = await _dbHelper.database;

    // جلب بيانات المرتجع
    final result = await db.query(
      'supplier_returns',
      where: 'id = ?',
      whereArgs: [returnId],
    );

    if (result.isEmpty) throw Exception('المرتجع غير موجود');

    final returnData = SupplierReturn.fromMap(result.first);
    if (returnData.isDelivered) throw Exception('المرتجع تم تسليمه مسبقاً');

    await db.transaction((txn) async {
      // 1. تحديث حالة المرتجع
      await txn.update(
        'supplier_returns',
        {
          'status': 'delivered',
          'delivered_date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [returnId],
      );
    });

    // 2. خصم من المخزون
    await _stockDao.addSupplierReturnMovement(
      productId: returnData.productId,
      returnId: returnId,
      quantity: returnData.quantity,
      notes: 'مرتجع للمورد',
    );

    // 3. تقليل دين المورد
    await _ledgerDao.addReturnEntry(
      supplierId: returnData.supplierId,
      returnId: returnId,
      amount: returnData.amount,
      description: 'مرتجع بضاعة',
    );
  }

  /// جلب مرتجعات مورد معين
  Future<List<SupplierReturn>> getSupplierReturns(String supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_returns',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SupplierReturn.fromMap(e)).toList();
  }

  /// جلب المرتجعات الجاهزة للتسليم
  Future<List<SupplierReturn>> getPreparedReturns() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_returns',
      where: 'status = ?',
      whereArgs: ['prepared'],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SupplierReturn.fromMap(e)).toList();
  }

  /// جلب جميع المرتجعات
  Future<List<SupplierReturn>> getAllReturns({int limit = 50}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_returns',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((e) => SupplierReturn.fromMap(e)).toList();
  }

  /// حذف مرتجع (فقط إذا لم يُسلّم)
  Future<void> deleteReturn(String returnId) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'supplier_returns',
      where: 'id = ?',
      whereArgs: [returnId],
    );

    if (result.isEmpty) throw Exception('المرتجع غير موجود');
    if (result.first['status'] == 'delivered') {
      throw Exception('لا يمكن حذف مرتجع تم تسليمه');
    }

    await db.delete(
      'supplier_returns',
      where: 'id = ?',
      whereArgs: [returnId],
    );
  }

  /// إحصائيات المرتجعات
  Future<Map<String, dynamic>> getReturnsStats({String? supplierId}) async {
    final db = await _dbHelper.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (supplierId != null) {
      whereClause += ' AND supplier_id = ?';
      whereArgs.add(supplierId);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(CASE WHEN status = 'prepared' THEN 1 ELSE 0 END) as prepared_count,
        SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered_count,
        COALESCE(SUM(CASE WHEN status = 'prepared' THEN amount ELSE 0 END), 0) as prepared_amount,
        COALESCE(SUM(CASE WHEN status = 'delivered' THEN amount ELSE 0 END), 0) as delivered_amount
      FROM supplier_returns
      WHERE $whereClause
    ''', whereArgs);

    return result.first;
  }
}
