import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../../features/debts/domain/entities/debt_payment.dart';
import '../database_helper.dart';

/// 💳 DAO لإدارة دفعات تسديد الديون
class DebtPaymentDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();

  /// إضافة دفعة تسديد جديدة
  Future<String> insertPayment(DebtPayment payment) async {
    final db = await _dbHelper.database;

    try {
      await db.insert('debt_payments', payment.toMap());

      developer.log(
        '✅ تم تسجيل دفعة تسديد: ${payment.amount} د.ع',
        name: 'DebtPaymentDAO',
      );

      return payment.id;
    } catch (e) {
      developer.log(
        '❌ خطأ في تسجيل الدفعة: $e',
        name: 'DebtPaymentDAO',
      );
      rethrow;
    }
  }

  /// إنشاء دفعة تسديد جديدة
  Future<String> createPayment({
    required String customerDebtId,
    String? saleId,
    required double amount,
    required String paymentMethod,
    required String cashierId,
    required String cashierName,
    String? notes,
  }) async {
    final payment = DebtPayment(
      id: _uuid.v4(),
      customerDebtId: customerDebtId,
      saleId: saleId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: DateTime.now(),
      cashierId: cashierId,
      cashierName: cashierName,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return await insertPayment(payment);
  }

  /// جلب دفعة بواسطة المعرف
  Future<DebtPayment?> getPaymentById(String id) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return DebtPayment.fromMap(results.first);
  }

  /// جلب جميع دفعات عميل معين
  Future<List<DebtPayment>> getPaymentsByCustomerDebt(
    String customerDebtId,
  ) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      where: 'customer_debt_id = ?',
      whereArgs: [customerDebtId],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => DebtPayment.fromMap(map)).toList();
  }

  /// جلب دفعات بيع معين
  Future<List<DebtPayment>> getPaymentsBySale(String saleId) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => DebtPayment.fromMap(map)).toList();
  }

  /// جلب جميع الدفعات
  Future<List<DebtPayment>> getAllPayments() async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => DebtPayment.fromMap(map)).toList();
  }

  /// جلب دفعات ضمن فترة زمنية
  Future<List<DebtPayment>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      where: 'payment_date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => DebtPayment.fromMap(map)).toList();
  }

  /// حساب إجمالي المدفوعات لعميل
  Future<double> getTotalPaymentsForCustomer(String customerDebtId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM debt_payments WHERE customer_debt_id = ?',
      [customerDebtId],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب إجمالي المدفوعات اليوم
  Future<double> getTodayPayments() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM debt_payments WHERE payment_date >= ?',
      [startOfDay.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب إجمالي المدفوعات خلال فترة
  Future<double> getTotalPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM debt_payments WHERE payment_date BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حذف دفعة
  Future<void> deletePayment(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'debt_payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    developer.log(
      '✅ تم حذف دفعة التسديد: $id',
      name: 'DebtPaymentDAO',
    );
  }

  /// جلب آخر دفعات (للعرض في Dashboard)
  Future<List<DebtPayment>> getRecentPayments({int limit = 10}) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'debt_payments',
      orderBy: 'payment_date DESC',
      limit: limit,
    );

    return results.map((map) => DebtPayment.fromMap(map)).toList();
  }

  /// إحصائيات الدفعات حسب الكاشير
  Future<Map<String, double>> getPaymentsByCashier(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT cashier_name, SUM(amount) as total
      FROM debt_payments
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY cashier_name
      ORDER BY total DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, double> paymentsByCashier = {};
    for (final row in results) {
      paymentsByCashier[row['cashier_name'] as String] =
          (row['total'] as num).toDouble();
    }

    return paymentsByCashier;
  }
}
