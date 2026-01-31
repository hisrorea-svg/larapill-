import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';
import '../../models/supplier_payment.dart';
import 'supplier_ledger_dao.dart';

/// DAO لدفعات الموردين
class SupplierPaymentsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupplierLedgerDao _ledgerDao = SupplierLedgerDao();

  /// إضافة دفعة جديدة
  Future<String> createPayment({
    required String supplierId,
    required double amount,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();

    await db.insert('supplier_payments', {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });

    // تسجيل في دفتر الأستاذ
    await _ledgerDao.addPaymentEntry(
      supplierId: supplierId,
      paymentId: id,
      amount: amount,
      description: notes ?? 'دفعة ${_getPaymentMethodLabel(paymentMethod)}',
    );

    return id;
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدية';
      case 'bank':
        return 'تحويل بنكي';
      case 'check':
        return 'شيك';
      default:
        return method;
    }
  }

  /// جلب دفعات مورد معين
  Future<List<SupplierPayment>> getSupplierPayments(String supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SupplierPayment.fromMap(e)).toList();
  }

  /// جلب جميع الدفعات
  Future<List<SupplierPayment>> getAllPayments({int limit = 50}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_payments',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((e) => SupplierPayment.fromMap(e)).toList();
  }

  /// جلب دفعات اليوم
  Future<List<SupplierPayment>> getTodayPayments() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final result = await db.query(
      'supplier_payments',
      where: 'created_at >= ?',
      whereArgs: [startOfDay.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SupplierPayment.fromMap(e)).toList();
  }

  /// إجمالي الدفعات لمورد
  Future<double> getSupplierTotalPayments(String supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM supplier_payments
      WHERE supplier_id = ?
    ''', [supplierId]);

    return (result.first['total'] as num).toDouble();
  }

  /// إحصائيات الدفعات
  Future<Map<String, dynamic>> getPaymentsStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (fromDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as payment_count,
        COALESCE(SUM(amount), 0) as total_amount,
        COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0) as cash_amount,
        COALESCE(SUM(CASE WHEN payment_method = 'bank' THEN amount ELSE 0 END), 0) as bank_amount,
        COALESCE(SUM(CASE WHEN payment_method = 'check' THEN amount ELSE 0 END), 0) as check_amount
      FROM supplier_payments
      WHERE $whereClause
    ''', whereArgs);

    return result.first;
  }
}
