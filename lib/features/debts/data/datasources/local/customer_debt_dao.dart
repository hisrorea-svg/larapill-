import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../../../domain/entities/customer_debt.dart';
import '../../../../../database/database_helper.dart';

/// 💰 DAO لإدارة ديون العملاء
class CustomerDebtDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();

  /// إنشاء أو تحديث دين عميل
  Future<void> upsertCustomerDebt({
    required String customerName,
    String? customerPhone,
    required double debtAmount,
    required String saleId,
  }) async {
    final db = await _dbHelper.database;

    try {
      // البحث عن العميل الحالي (بالاسم أو الهاتف)
      String? existingDebtId;

      if (customerPhone != null && customerPhone.isNotEmpty) {
        final existing = await db.query(
          'customer_debts',
          where: 'customer_phone = ?',
          whereArgs: [customerPhone],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          existingDebtId = existing.first['id'] as String;
        }
      }

      // إذا لم نجد بالهاتف، نبحث بالاسم
      if (existingDebtId == null) {
        final existing = await db.query(
          'customer_debts',
          where: 'customer_name = ?',
          whereArgs: [customerName],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          existingDebtId = existing.first['id'] as String;
        }
      }

      final now = DateTime.now();

      if (existingDebtId != null) {
        // تحديث الدين الموجود
        final currentDebt = await getCustomerDebtById(existingDebtId);
        if (currentDebt != null) {
          await db.update(
            'customer_debts',
            {
              'total_debt': currentDebt.totalDebt + debtAmount,
              'remaining_debt': currentDebt.remainingDebt + debtAmount,
              'sales_count': currentDebt.salesCount + 1,
              'last_transaction_date': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [existingDebtId],
          );

          developer.log(
            '✅ تم تحديث دين العميل: $customerName - دين جديد: $debtAmount',
            name: 'CustomerDebtDAO',
          );
        }
      } else {
        // إنشاء دين جديد
        final newDebt = CustomerDebt(
          id: _uuid.v4(),
          customerName: customerName,
          customerPhone: customerPhone,
          totalDebt: debtAmount,
          totalPaid: 0,
          remainingDebt: debtAmount,
          salesCount: 1,
          lastTransactionDate: now,
          createdAt: now,
          updatedAt: now,
        );

        await db.insert('customer_debts', newDebt.toMap());

        developer.log(
          '✅ تم إنشاء دين جديد للعميل: $customerName - المبلغ: $debtAmount',
          name: 'CustomerDebtDAO',
        );
      }
    } catch (e) {
      developer.log(
        '❌ خطأ في حفظ دين العميل: $e',
        name: 'CustomerDebtDAO',
      );
      rethrow;
    }
  }

  /// الحصول على دين عميل بواسطة المعرف
  Future<CustomerDebt?> getCustomerDebtById(String id) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'customer_debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CustomerDebt.fromMap(results.first);
  }

  /// الحصول على دين عميل بواسطة رقم الهاتف
  Future<CustomerDebt?> getCustomerDebtByPhone(String phone) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'customer_debts',
      where: 'customer_phone = ?',
      whereArgs: [phone],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CustomerDebt.fromMap(results.first);
  }

  /// الحصول على دين عميل بواسطة الاسم
  Future<CustomerDebt?> getCustomerDebtByName(String name) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'customer_debts',
      where: 'customer_name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CustomerDebt.fromMap(results.first);
  }

  /// جلب جميع العملاء المدينين
  Future<List<CustomerDebt>> getAllDebts({bool onlyWithDebt = true}) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'customer_debts',
      where: onlyWithDebt ? 'remaining_debt > 0' : null,
      orderBy: 'remaining_debt DESC, last_transaction_date DESC',
    );

    return results.map((map) => CustomerDebt.fromMap(map)).toList();
  }

  /// حساب إجمالي الديون
  Future<double> getTotalDebts() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT SUM(remaining_debt) as total FROM customer_debts WHERE remaining_debt > 0',
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب عدد العملاء المدينين
  Future<int> getDebtorsCount() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customer_debts WHERE remaining_debt > 0',
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// تسجيل دفعة وتحديث الدين
  Future<void> recordPayment({
    required String customerDebtId,
    required double amount,
  }) async {
    final db = await _dbHelper.database;

    try {
      final debt = await getCustomerDebtById(customerDebtId);
      if (debt == null) {
        throw Exception('لم يتم العثور على دين العميل');
      }

      if (amount > debt.remainingDebt) {
        throw Exception('المبلغ المدفوع أكبر من الدين المتبقي');
      }

      await db.update(
        'customer_debts',
        {
          'total_paid': debt.totalPaid + amount,
          'remaining_debt': debt.remainingDebt - amount,
          'last_transaction_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerDebtId],
      );

      developer.log(
        '✅ تم تسجيل دفعة: $amount للعميل: ${debt.customerName}',
        name: 'CustomerDebtDAO',
      );
    } catch (e) {
      developer.log(
        '❌ خطأ في تسجيل الدفعة: $e',
        name: 'CustomerDebtDAO',
      );
      rethrow;
    }
  }

  /// حذف دين عميل (إذا تم التسديد بالكامل)
  Future<void> deleteDebt(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'customer_debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// البحث عن عملاء مدينين
  Future<List<CustomerDebt>> searchDebts(String query) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'customer_debts',
      where: 'customer_name LIKE ? OR customer_phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'remaining_debt DESC',
    );

    return results.map((map) => CustomerDebt.fromMap(map)).toList();
  }
}
