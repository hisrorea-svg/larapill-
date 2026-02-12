/// Customer Debts Drift DAO - Type-safe database access for debts
///
/// This DAO handles all customer debt-releated operations.
library customer_debt_drift_dao;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';
import 'package:uuid/uuid.dart';

part 'customer_debt_drift_dao.g.dart';

@DriftAccessor(tables: [CustomerDebts])
class CustomerDebtDriftDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDebtDriftDaoMixin {
  CustomerDebtDriftDao(super.db);

  /// Find debt record by customer name
  Future<CustomerDebtEntry?> findByName(String name) {
    return (select(customerDebts)..where((d) => d.customerName.equals(name)))
        .getSingleOrNull();
  }

  /// Upsert customer debt (used during sales)
  Future<void> upsertDebt({
    required String customerName,
    required String? customerPhone,
    required double debtAmount,
  }) async {
    final existing = await findByName(customerName);
    final now = DateTime.now();

    if (existing == null) {
      // Create new record
      await into(customerDebts).insert(
        CustomerDebtsCompanion.insert(
          id: const Uuid().v4(),
          customerName: customerName,
          customerPhone: Value(customerPhone),
          totalDebt: Value(debtAmount),
          remainingDebt: Value(debtAmount),
          salesCount: const Value(1),
          lastTransactionDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      // Update existing
      await (update(customerDebts)..where((d) => d.id.equals(existing.id)))
          .write(
        CustomerDebtsCompanion(
          customerPhone: Value(customerPhone ?? existing.customerPhone),
          totalDebt: Value(existing.totalDebt + debtAmount),
          remainingDebt: Value(existing.remainingDebt + debtAmount),
          salesCount: Value(existing.salesCount + 1),
          lastTransactionDate: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Get all debts
  Future<List<CustomerDebtEntry>> getAllDebts() {
    return (select(customerDebts)
          ..orderBy([(d) => OrderingTerm.desc(d.lastTransactionDate)]))
        .get();
  }

  /// Watch total active debt
  Stream<double> watchTotalActiveDebt() {
    return (selectOnly(customerDebts)
          ..addColumns([customerDebts.remainingDebt.sum()]))
        .map(
            (row) => row.read<double>(customerDebts.remainingDebt.sum()) ?? 0.0)
        .watchSingle();
  }

  /// Get total remaining debts amount
  Future<double> getTotalDebts() async {
    final result = await (selectOnly(customerDebts)
          ..addColumns([customerDebts.remainingDebt.sum()]))
        .getSingle();
    return result.read<double>(customerDebts.remainingDebt.sum()) ?? 0.0;
  }

  /// Get count of customers with remaining debt
  Future<int> getDebtorsCount() async {
    final result = await (selectOnly(customerDebts)
          ..addColumns([customerDebts.id.count()])
          ..where(customerDebts.remainingDebt.isBiggerThanValue(0)))
        .getSingle();
    return result.read<int>(customerDebts.id.count()) ?? 0;
  }

  /// Get all debts with remaining balance > 0
  Future<List<CustomerDebtEntry>> getAllDebtsWithBalance() {
    return (select(customerDebts)
          ..where((d) => d.remainingDebt.isBiggerThanValue(0))
          ..orderBy([(d) => OrderingTerm.desc(d.lastTransactionDate)]))
        .get();
  }

  /// Search debts with pagination - PROFESSIONAL PERFORMANCE
  Future<List<CustomerDebtEntry>> searchDebts({
    String? query,
    String? status, // 'overdue', 'warning', 'normal'
    String sortBy = 'date', // 'date', 'amount', 'name'
    bool sortDesc = true,
    int limit = 20,
    int offset = 0,
  }) {
    var selectQuery = select(customerDebts)
      ..where((d) => d.remainingDebt.isBiggerThanValue(0));

    // Apply search query
    if (query != null && query.isNotEmpty) {
      selectQuery = selectQuery
        ..where((d) =>
            d.customerName.contains(query) | d.customerPhone.contains(query));
    }

    // Apply status filter based on days
    if (status != null) {
      final now = DateTime.now();
      switch (status) {
        case 'overdue':
          final cutoff = now.subtract(const Duration(days: 30));
          selectQuery = selectQuery
            ..where((d) => d.lastTransactionDate.isSmallerThanValue(cutoff));
          break;
        case 'warning':
          final warningCutoff = now.subtract(const Duration(days: 15));
          final overdueCutoff = now.subtract(const Duration(days: 30));
          selectQuery = selectQuery
            ..where((d) => d.lastTransactionDate
                .isBetweenValues(overdueCutoff, warningCutoff));
          break;
        case 'normal':
          final cutoff = now.subtract(const Duration(days: 15));
          selectQuery = selectQuery
            ..where((d) => d.lastTransactionDate.isBiggerOrEqualValue(cutoff));
          break;
      }
    }

    // Apply sorting
    OrderingTerm orderingTerm;
    switch (sortBy) {
      case 'amount':
        orderingTerm = OrderingTerm(
          expression: customerDebts.remainingDebt,
          mode: sortDesc ? OrderingMode.desc : OrderingMode.asc,
        );
        break;
      case 'name':
        orderingTerm = OrderingTerm(
          expression: customerDebts.customerName,
          mode: sortDesc ? OrderingMode.desc : OrderingMode.asc,
        );
        break;
      case 'date':
      default:
        orderingTerm = OrderingTerm(
          expression: customerDebts.lastTransactionDate,
          mode: sortDesc ? OrderingMode.desc : OrderingMode.asc,
        );
    }

    selectQuery = selectQuery..orderBy([(d) => orderingTerm]);

    // Apply pagination
    selectQuery = selectQuery..limit(limit, offset: offset);

    return selectQuery.get();
  }

  /// Get total count for pagination
  Future<int> getDebtsCount({
    String? query,
    String? status,
  }) async {
    var countQuery = selectOnly(customerDebts)
      ..addColumns([customerDebts.id.count()])
      ..where(customerDebts.remainingDebt.isBiggerThanValue(0));

    if (query != null && query.isNotEmpty) {
      countQuery = countQuery
        ..where(customerDebts.customerName.contains(query) |
            customerDebts.customerPhone.contains(query));
    }

    if (status != null) {
      final now = DateTime.now();
      switch (status) {
        case 'overdue':
          final cutoff = now.subtract(const Duration(days: 30));
          countQuery = countQuery
            ..where(
                customerDebts.lastTransactionDate.isSmallerThanValue(cutoff));
          break;
        case 'warning':
          final warningCutoff = now.subtract(const Duration(days: 15));
          final overdueCutoff = now.subtract(const Duration(days: 30));
          countQuery = countQuery
            ..where(customerDebts.lastTransactionDate
                .isBetweenValues(overdueCutoff, warningCutoff));
          break;
        case 'normal':
          final cutoff = now.subtract(const Duration(days: 15));
          countQuery = countQuery
            ..where(
                customerDebts.lastTransactionDate.isBiggerOrEqualValue(cutoff));
          break;
      }
    }

    final result = await countQuery.getSingle();
    return result.read<int>(customerDebts.id.count()) ?? 0;
  }

  /// Get comprehensive debts statistics summary - Optimized via custom SQL
  Future<Map<String, double>> getDebtsStatsSummary() async {
    final now = DateTime.now();
    final overdueCutoff = now.subtract(const Duration(days: 30));

    final result = await customSelect(
      '''
      SELECT
        COALESCE(SUM(remaining_debt), 0) as total_debts,
        COUNT(*) as debtors_count,
        COALESCE(SUM(CASE WHEN last_transaction_date < ? THEN remaining_debt ELSE 0 END), 0) as overdue_debts,
        COUNT(CASE WHEN last_transaction_date < ? THEN 1 END) as overdue_count
      FROM customer_debts
      WHERE remaining_debt > 0
      ''',
      variables: [Variable(overdueCutoff), Variable(overdueCutoff)],
      readsFrom: {customerDebts},
    ).getSingle();

    return {
      'totalDebts': result.read<double>('total_debts'),
      'debtorsCount': result.read<int>('debtors_count').toDouble(),
      'overdueDebts': result.read<double>('overdue_debts'),
      'overdueCount': result.read<int>('overdue_count').toDouble(),
    };
  }

  /// Get counts for all statuses in one go via custom SQL
  Future<Map<String, int>> getDebtsCountsByStatus() async {
    final now = DateTime.now();
    final warningCutoff = now.subtract(const Duration(days: 15));
    final overdueCutoff = now.subtract(const Duration(days: 30));

    final result = await customSelect(
      '''
      SELECT
        COUNT(CASE WHEN last_transaction_date < ? THEN 1 END) as overdue,
        COUNT(CASE WHEN last_transaction_date >= ? AND last_transaction_date < ? THEN 1 END) as warning,
        COUNT(CASE WHEN last_transaction_date >= ? THEN 1 END) as normal
      FROM customer_debts
      WHERE remaining_debt > 0
      ''',
      variables: [
        Variable(overdueCutoff),
        Variable(overdueCutoff),
        Variable(warningCutoff),
        Variable(warningCutoff),
      ],
      readsFrom: {customerDebts},
    ).getSingle();

    return {
      'overdue': result.read<int>('overdue'),
      'warning': result.read<int>('warning'),
      'normal': result.read<int>('normal'),
    };
  }

  /// Record a payment against a customer debt
  /// Updates totalPaid and remainingDebt
  Future<bool> recordPayment({
    required String customerDebtId,
    required double amount,
  }) async {
    final debt = await (select(customerDebts)
          ..where((d) => d.id.equals(customerDebtId)))
        .getSingleOrNull();

    if (debt == null) return false;

    final now = DateTime.now();
    final newTotalPaid = debt.totalPaid + amount;
    final newRemainingDebt =
        (debt.remainingDebt - amount).clamp(0.0, double.infinity);

    await (update(customerDebts)..where((d) => d.id.equals(customerDebtId)))
        .write(
      CustomerDebtsCompanion(
        totalPaid: Value(newTotalPaid),
        remainingDebt: Value(newRemainingDebt),
        lastTransactionDate: Value(now),
        updatedAt: Value(now),
      ),
    );

    return true;
  }

  /// Find debt record by ID
  Future<CustomerDebtEntry?> findById(String id) {
    return (select(customerDebts)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }
}
