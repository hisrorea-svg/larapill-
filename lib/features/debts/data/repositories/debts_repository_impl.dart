import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/daos/customer_debt_drift_dao.dart';
import '../../../../core/database/drift/daos/debt_payment_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../features/pos/data/repositories/sales_repository.dart';
import '../../domain/entities/customer_debt.dart';
import '../../domain/entities/debts_stats.dart';
import '../../domain/entities/debt_status.dart';
import '../../domain/entities/debts_search_result.dart';
import '../../domain/repositories/debts_repository.dart';
import '../../presentation/providers/debts_providers.dart';

/// تنفيذ مستودع الديون
class DebtsRepositoryImpl implements DebtsRepository {
  final CustomerDebtDriftDao _debtDao;
  final DebtPaymentDriftDao _paymentDao;

  DebtsRepositoryImpl(this._debtDao, this._paymentDao);

  /// تحويل CustomerDebtEntry إلى CustomerDebt entity
  CustomerDebt _mapEntryToEntity(CustomerDebtEntry entry) {
    return CustomerDebt(
      id: entry.id,
      customerName: entry.customerName,
      customerPhone: entry.customerPhone,
      totalDebt: entry.totalDebt,
      totalPaid: entry.totalPaid,
      remainingDebt: entry.remainingDebt,
      salesCount: entry.salesCount,
      lastTransactionDate: entry.lastTransactionDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Search debts with pagination - PROFESSIONAL
  @override
  Future<DebtsSearchResult> searchDebts({
    String? query,
    DebtStatus? status,
    DebtSortType sortType = DebtSortType.newest,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // Convert sort type
      String sortBy = 'date';
      bool sortDesc = true;

      switch (sortType) {
        case DebtSortType.newest:
          sortBy = 'date';
          sortDesc = true;
          break;
        case DebtSortType.oldest:
          sortBy = 'date';
          sortDesc = false;
          break;
        case DebtSortType.highestAmount:
          sortBy = 'amount';
          sortDesc = true;
          break;
        case DebtSortType.lowestAmount:
          sortBy = 'amount';
          sortDesc = false;
          break;
      }

      // Get paginated results
      final entries = await _debtDao.searchDebts(
        query: query?.isEmpty == true ? null : query,
        status: status?.name,
        sortBy: sortBy,
        sortDesc: sortDesc,
        limit: pageSize,
        offset: page * pageSize,
      );

      // Get total count
      final totalCount = await _debtDao.getDebtsCount(
        query: query?.isEmpty == true ? null : query,
        status: status?.name,
      );

      return DebtsSearchResult(
        debts: entries.map(_mapEntryToEntity).toList(),
        totalCount: totalCount,
        hasMore: (page + 1) * pageSize < totalCount,
      );
    } catch (e, stack) {
      dev.log(
        'Error searching debts',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return DebtsSearchResult.empty();
    }
  }

  @override
  Future<List<CustomerDebt>> getAllDebtsWithBalance() async {
    try {
      final entries = await _debtDao.getAllDebtsWithBalance();
      return entries.map(_mapEntryToEntity).toList();
    } catch (e, stack) {
      dev.log(
        'Error fetching debts with balance',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return [];
    }
  }

  @override
  Future<int> getDebtsCount({String? query, DebtStatus? status}) async {
    try {
      return await _debtDao.getDebtsCount(
        query: query?.isEmpty == true ? null : query,
        status: status?.name,
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching debts count',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return 0;
    }
  }

  @override
  Future<Map<DebtStatus, int>> getDebtsCountsByStatus() async {
    try {
      final counts = await _debtDao.getDebtsCountsByStatus();
      return {
        DebtStatus.overdue: counts['overdue'] ?? 0,
        DebtStatus.warning: counts['warning'] ?? 0,
        DebtStatus.normal: counts['normal'] ?? 0,
      };
    } catch (e, stack) {
      dev.log(
        'Error fetching debts counts by status',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return {
        DebtStatus.overdue: 0,
        DebtStatus.warning: 0,
        DebtStatus.normal: 0,
      };
    }
  }

  @override
  Future<DebtsStats> getDebtsStats() async {
    try {
      // 1. Get statistics summary directly from DAO (Efficient SQL)
      final statsSummary = await _debtDao.getDebtsStatsSummary();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));

      // 2. Get payment stats (also efficient SQL)
      final collectedThisMonth = await _paymentDao.getTotalPaymentsByDateRange(
        startOfMonth,
        endOfMonth,
      );

      final paymentsThisMonth = await _paymentDao.getPaymentsCountByDateRange(
        startOfMonth,
        endOfMonth,
      );

      return DebtsStats(
        totalDebts: statsSummary['totalDebts'] ?? 0.0,
        debtorsCount: (statsSummary['debtorsCount'] ?? 0).toInt(),
        overdueDebts: statsSummary['overdueDebts'] ?? 0.0,
        overdueCount: (statsSummary['overdueCount'] ?? 0).toInt(),
        collectedThisMonth: collectedThisMonth,
        paymentsThisMonth: paymentsThisMonth,
      );
    } catch (e, stack) {
      dev.log(
        'Error fetching debts stats',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return DebtsStats.empty();
    }
  }

  @override
  Future<List<CustomerDebt>> getOverdueDebts() async {
    try {
      final entries = await _debtDao.searchDebts(status: 'overdue');
      return entries.map(_mapEntryToEntity).toList();
    } catch (e, stack) {
      dev.log(
        'Error fetching overdue debts',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return [];
    }
  }

  @override
  Future<List<CustomerDebt>> getDebtsByStatus(DebtStatus status) async {
    try {
      final entries = await _debtDao.searchDebts(status: status.name);
      return entries.map(_mapEntryToEntity).toList();
    } catch (e, stack) {
      dev.log(
        'Error fetching debts by status',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return [];
    }
  }

  @override
  Future<bool> recordPayment({
    required String customerDebtId,
    required double amount,
    required String paymentMethod,
    required String cashierId,
    required String cashierName,
    String? notes,
  }) async {
    try {
      return await _debtDao.attachedDatabase.transaction(() async {
        // 1. تسجل الدفعة في سجل المدفوعات
        await _paymentDao.insertPayment(
          customerDebtId: customerDebtId,
          amount: amount,
          paymentMethod: paymentMethod,
          cashierId: cashierId,
          cashierName: cashierName,
          notes: notes,
        );

        // 2. تحديث رصيد الدين للعميل
        return await _debtDao.recordPayment(
          customerDebtId: customerDebtId,
          amount: amount,
        );
      });
    } catch (e, stack) {
      dev.log(
        'Error recording payment',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return false;
    }
  }

  @override
  Future<CustomerDebt?> getDebtById(String id) async {
    try {
      final entry = await _debtDao.findById(id);
      if (entry == null) return null;
      return _mapEntryToEntity(entry);
    } catch (e, stack) {
      dev.log(
        'Error fetching debt by id',
        error: e,
        stackTrace: stack,
        name: 'DebtsRepository',
      );
      return null;
    }
  }
}

// ============ Providers ============

/// Provider لمستودع الديون
final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return DebtsRepositoryImpl(
    ref.watch(customerDebtDriftDaoProvider),
    ref.watch(debtPaymentDriftDaoProvider),
  );
});
