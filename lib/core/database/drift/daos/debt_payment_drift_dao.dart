/// Debt Payments Drift DAO - Type-safe database access for debt payments
///
/// This DAO handles all debt payment recording and querying.
library debt_payment_drift_dao;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';
import 'package:uuid/uuid.dart';

part 'debt_payment_drift_dao.g.dart';

@DriftAccessor(tables: [DebtPayments])
class DebtPaymentDriftDao extends DatabaseAccessor<AppDatabase>
    with _$DebtPaymentDriftDaoMixin {
  DebtPaymentDriftDao(super.db);

  /// Insert a new payment record
  Future<String> insertPayment({
    required String customerDebtId,
    String? saleId,
    required double amount,
    required String paymentMethod,
    required String cashierId,
    required String cashierName,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    await into(debtPayments).insert(
      DebtPaymentsCompanion.insert(
        id: id,
        customerDebtId: customerDebtId,
        saleId: Value(saleId),
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: now,
        cashierId: cashierId,
        cashierName: cashierName,
        notes: Value(notes),
        createdAt: now,
      ),
    );

    return id;
  }

  /// Get payment by ID
  Future<DebtPaymentEntry?> getPaymentById(String id) {
    return (select(debtPayments)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get all payments for a customer debt
  Future<List<DebtPaymentEntry>> getPaymentsByCustomerDebt(
      String customerDebtId) {
    return (select(debtPayments)
          ..where((p) => p.customerDebtId.equals(customerDebtId))
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  /// Get payments by sale ID
  Future<List<DebtPaymentEntry>> getPaymentsBySale(String saleId) {
    return (select(debtPayments)
          ..where((p) => p.saleId.equals(saleId))
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  /// Get all payments
  Future<List<DebtPaymentEntry>> getAllPayments() {
    return (select(debtPayments)
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  /// Get payments in date range
  Future<List<DebtPaymentEntry>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(debtPayments)
          ..where((p) => p.paymentDate.isBetweenValues(startDate, endDate))
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  /// Get total payments for a customer debt
  Future<double> getTotalPaymentsForCustomer(String customerDebtId) async {
    final result = await (selectOnly(debtPayments)
          ..addColumns([debtPayments.amount.sum()])
          ..where(debtPayments.customerDebtId.equals(customerDebtId)))
        .getSingle();
    return result.read<double>(debtPayments.amount.sum()) ?? 0.0;
  }

  /// Get today's total payments
  Future<double> getTodayPayments() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final result = await (selectOnly(debtPayments)
          ..addColumns([debtPayments.amount.sum()])
          ..where(debtPayments.paymentDate.isBiggerOrEqualValue(startOfDay)))
        .getSingle();
    return result.read<double>(debtPayments.amount.sum()) ?? 0.0;
  }

  /// Get total payments in date range
  Future<double> getTotalPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await (selectOnly(debtPayments)
          ..addColumns([debtPayments.amount.sum()])
          ..where(debtPayments.paymentDate.isBetweenValues(startDate, endDate)))
        .getSingle();
    return result.read<double>(debtPayments.amount.sum()) ?? 0.0;
  }

  /// Delete a payment
  Future<void> deletePayment(String id) {
    return (delete(debtPayments)..where((p) => p.id.equals(id))).go();
  }

  /// Get recent payments (for dashboard)
  Future<List<DebtPaymentEntry>> getRecentPayments({int limit = 10}) {
    return (select(debtPayments)
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)])
          ..limit(limit))
        .get();
  }

  /// Get count of payments in date range
  Future<int> getPaymentsCountByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await (selectOnly(debtPayments)
          ..addColumns([debtPayments.id.count()])
          ..where(debtPayments.paymentDate.isBetweenValues(startDate, endDate)))
        .getSingle();
    return result.read<int>(debtPayments.id.count()) ?? 0;
  }
}

/// Provider for DebtPaymentDriftDao
final debtPaymentDriftDaoProvider = Provider<DebtPaymentDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DebtPaymentDriftDao(db);
});
