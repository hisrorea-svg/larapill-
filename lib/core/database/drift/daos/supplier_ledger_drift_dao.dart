/// Supplier Ledger Drift DAO - Type-safe database access for supplier ledger
library supplier_ledger_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';

part 'supplier_ledger_drift_dao.g.dart';

/// DAO for SupplierLedger table with type-safe queries
@DriftAccessor(tables: [SupplierLedger])
class SupplierLedgerDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierLedgerDriftDaoMixin {
  SupplierLedgerDriftDao(super.db);

  // 📖 READ OPERATIONS

  /// Get all ledger entries for a supplier
  Future<List<SupplierLedgerData>> getSupplierLedger(String supplierId,
      {int limit = 100}) {
    return (select(supplierLedger)
          ..where((t) => t.supplierId.equals(supplierId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get current balance for a supplier
  Future<double> getBalance(String supplierId) async {
    final result = await (selectOnly(supplierLedger)
          ..addColumns([supplierLedger.balanceAfter])
          ..where(supplierLedger.supplierId.equals(supplierId))
          ..orderBy([OrderingTerm.desc(supplierLedger.createdAt)])
          ..limit(1))
        .map((row) => row.read(supplierLedger.balanceAfter) ?? 0.0)
        .getSingleOrNull();

    return result ?? 0.0;
  }

  /// Get all supplier balances
  Future<Map<String, double>> getAllBalances() async {
    final query = selectOnly(supplierLedger)
      ..addColumns([
        supplierLedger.supplierId,
        supplierLedger.balanceAfter,
      ])
      ..orderBy([OrderingTerm.desc(supplierLedger.createdAt)]);

    final results = await query
        .map((row) => (
              row.read(supplierLedger.supplierId) as String,
              row.read(supplierLedger.balanceAfter) ?? 0.0,
            ))
        .get();

    // Keep only the latest balance for each supplier
    final balances = <String, double>{};
    for (final (supplierId, balance) in results) {
      balances.putIfAbsent(supplierId, () => balance);
    }

    return balances;
  }

  // 📊 OVERDUE DETECTION

  /// Check if there are any overdue debts
  ///
  /// A debt is considered overdue if:
  /// 1. The supplier has a positive balance (debt)
  /// 2. The last transaction is older than [overdueDays] days
  /// 3. There are no recent payments
  Future<bool> hasOverdueDebts({int overdueDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: overdueDays));

    // Get suppliers with positive balance
    final balances = await getAllBalances();
    final suppliersWithDebt =
        balances.entries.where((e) => e.value > 0).map((e) => e.key).toList();

    if (suppliersWithDebt.isEmpty) return false;

    // Check if any debt is overdue (last transaction older than cutoff)
    for (final supplierId in suppliersWithDebt) {
      final lastTransaction = await (selectOnly(supplierLedger)
            ..addColumns([supplierLedger.createdAt])
            ..where(supplierLedger.supplierId.equals(supplierId))
            ..orderBy([OrderingTerm.desc(supplierLedger.createdAt)])
            ..limit(1))
          .map((row) => row.read(supplierLedger.createdAt))
          .getSingleOrNull();

      if (lastTransaction != null && lastTransaction.isBefore(cutoffDate)) {
        return true;
      }
    }

    return false;
  }

  /// Get detailed overdue debts report
  ///
  /// Returns a list of suppliers with overdue debts including:
  /// - supplierId
  /// - currentBalance
  /// - daysOverdue
  /// - lastTransactionDate
  Future<List<Map<String, dynamic>>> getOverdueDebtsReport(
      {int overdueDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: overdueDays));
    final balances = await getAllBalances();
    final report = <Map<String, dynamic>>[];

    for (final entry in balances.entries) {
      if (entry.value <= 0) continue;

      final supplierId = entry.key;
      final lastTransaction = await (selectOnly(supplierLedger)
            ..addColumns([supplierLedger.createdAt])
            ..where(supplierLedger.supplierId.equals(supplierId))
            ..orderBy([OrderingTerm.desc(supplierLedger.createdAt)])
            ..limit(1))
          .map((row) => row.read(supplierLedger.createdAt))
          .getSingleOrNull();

      if (lastTransaction != null && lastTransaction.isBefore(cutoffDate)) {
        final daysOverdue = DateTime.now().difference(lastTransaction).inDays;
        report.add({
          'supplierId': supplierId,
          'currentBalance': entry.value,
          'daysOverdue': daysOverdue,
          'lastTransactionDate': lastTransaction,
        });
      }
    }

    // Sort by days overdue (most overdue first)
    report.sort(
        (a, b) => (b['daysOverdue'] as int).compareTo(a['daysOverdue'] as int));

    return report;
  }

  // 📊 STATISTICS

  /// Get total debts across all suppliers
  Future<double> getTotalDebts() async {
    final balances = await getAllBalances();
    return balances.values
        .where((b) => b > 0)
        .fold<double>(0.0, (a, b) => a + b);
  }

  /// Get supplier count with debts
  Future<int> getSuppliersWithDebtCount() async {
    final balances = await getAllBalances();
    return balances.values.where((b) => b > 0).length;
  }
}

/// Provider for SupplierLedgerDriftDao
final supplierLedgerDriftDaoProvider = Provider<SupplierLedgerDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SupplierLedgerDriftDao(db);
});
