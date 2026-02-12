import '../entities/customer_debt.dart';
import '../entities/debts_stats.dart';
import '../entities/debt_status.dart';
import '../entities/debts_search_result.dart';
import '../../presentation/providers/debts_providers.dart';

/// واجهة مستودع الديون
abstract class DebtsRepository {
  /// جلب جميع الديون مع رصيد متبقي
  Future<List<CustomerDebt>> getAllDebtsWithBalance();

  /// جلب إحصائيات الديون الموسعة
  Future<DebtsStats> getDebtsStats();

  /// جلب الديون المتأخرة فقط
  Future<List<CustomerDebt>> getOverdueDebts();

  /// جلب الديون حسب الحالة
  Future<List<CustomerDebt>> getDebtsByStatus(DebtStatus status);

  /// تسجيل دفعة
  Future<bool> recordPayment({
    required String customerDebtId,
    required double amount,
    required String paymentMethod,
    required String cashierId,
    required String cashierName,
    String? notes,
  });

  /// جلب دين عميل بواسطة ID
  Future<CustomerDebt?> getDebtById(String id);

  /// Search debts with pagination - PROFESSIONAL
  Future<DebtsSearchResult> searchDebts({
    String? query,
    DebtStatus? status,
    DebtSortType sortType,
    int page,
    int pageSize,
  });

  /// Get debts count
  Future<int> getDebtsCount({String? query, DebtStatus? status});

  /// Get counts by status in one call
  Future<Map<DebtStatus, int>> getDebtsCountsByStatus();
}
