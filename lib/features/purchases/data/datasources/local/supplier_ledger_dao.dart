import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../../database/database_helper.dart';
import '../../models/supplier_ledger_entry.dart';

/// DAO لدفتر أستاذ الموردين
class SupplierLedgerDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// إضافة قيد جديد
  Future<void> insertEntry(SupplierLedgerEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      'supplier_ledger',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// حساب رصيد المورد الحالي
  Future<double> getSupplierBalance(String supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT balance_after FROM supplier_ledger 
      WHERE supplier_id = ? 
      ORDER BY created_at DESC 
      LIMIT 1
    ''', [supplierId]);

    if (result.isEmpty) return 0.0;
    return (result.first['balance_after'] as num).toDouble();
  }

  /// جلب جميع قيود المورد
  Future<List<SupplierLedgerEntry>> getSupplierEntries(
      String supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'supplier_ledger',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SupplierLedgerEntry.fromMap(e)).toList();
  }

  /// حساب إجمالي ديون جميع الموردين
  Future<double> getTotalSuppliersDebt() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(balance) as total FROM (
        SELECT supplier_id, 
               (SELECT balance_after FROM supplier_ledger sl2 
                WHERE sl2.supplier_id = sl1.supplier_id 
                ORDER BY created_at DESC LIMIT 1) as balance
        FROM supplier_ledger sl1
        GROUP BY supplier_id
      )
    ''');

    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  /// إضافة قيد فاتورة جديدة
  Future<void> addInvoiceEntry({
    required String supplierId,
    required String invoiceId,
    required double amount,
    String? description,
  }) async {
    final currentBalance = await getSupplierBalance(supplierId);
    final newBalance = currentBalance + amount;

    final entry = SupplierLedgerEntry(
      id: const Uuid().v4(),
      supplierId: supplierId,
      referenceId: invoiceId,
      referenceType: 'invoice',
      amount: amount,
      balanceAfter: newBalance,
      description: description ?? 'فاتورة شراء',
      createdAt: DateTime.now(),
    );

    await insertEntry(entry);
  }

  /// إضافة قيد دفعة
  Future<void> addPaymentEntry({
    required String supplierId,
    required String paymentId,
    required double amount,
    String? description,
  }) async {
    final currentBalance = await getSupplierBalance(supplierId);
    final newBalance = currentBalance - amount; // دفعة تقلل الدين

    final entry = SupplierLedgerEntry(
      id: const Uuid().v4(),
      supplierId: supplierId,
      referenceId: paymentId,
      referenceType: 'payment',
      amount: -amount, // سالب لأنها مدين
      balanceAfter: newBalance,
      description: description ?? 'دفعة نقدية',
      createdAt: DateTime.now(),
    );

    await insertEntry(entry);
  }

  /// إضافة قيد مرتجع
  Future<void> addReturnEntry({
    required String supplierId,
    required String returnId,
    required double amount,
    String? description,
  }) async {
    final currentBalance = await getSupplierBalance(supplierId);
    final newBalance = currentBalance - amount; // مرتجع يقلل الدين

    final entry = SupplierLedgerEntry(
      id: const Uuid().v4(),
      supplierId: supplierId,
      referenceId: returnId,
      referenceType: 'return',
      amount: -amount,
      balanceAfter: newBalance,
      description: description ?? 'مرتجع بضاعة',
      createdAt: DateTime.now(),
    );

    await insertEntry(entry);
  }
}
