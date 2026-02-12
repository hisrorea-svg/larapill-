import '../repositories/purchases_repository.dart';

/// إحصائيات لوحة تحكم المشتريات
class DashboardStats {
  final int lowStockCount;
  final int pendingInvoices;
  final double pendingReturnsAmount;
  final int preparedReturnsCount;
  final double totalDebt;
  final double cashDebt;
  final double weeklyDebt;
  final double monthlyDebt;
  final double creditDebt;
  final bool hasOverdueDebt;
  final int overdueCount;
  final Map<String, double> debtBySupplier;

  const DashboardStats({
    this.lowStockCount = 0,
    this.pendingInvoices = 0,
    this.pendingReturnsAmount = 0,
    this.preparedReturnsCount = 0,
    this.totalDebt = 0,
    this.cashDebt = 0,
    this.weeklyDebt = 0,
    this.monthlyDebt = 0,
    this.creditDebt = 0,
    this.hasOverdueDebt = false,
    this.overdueCount = 0,
    this.debtBySupplier = const {},
  });

  /// نسبة الديون النقدية
  double get cashDebtPercent =>
      totalDebt > 0 ? (cashDebt / totalDebt) * 100 : 0;

  /// نسبة الديون الشهرية
  double get monthlyDebtPercent =>
      totalDebt > 0 ? (monthlyDebt / totalDebt) * 100 : 0;

  /// نسبة الديون الآجلة
  double get creditDebtPercent =>
      totalDebt > 0 ? (creditDebt / totalDebt) * 100 : 0;
}

/// Use Case: جلب إحصائيات لوحة التحكم
class GetDashboardStatsUseCase {
  final PurchasesRepository _repository;

  GetDashboardStatsUseCase({
    required PurchasesRepository repository,
  }) : _repository = repository;

  /// تنفيذ الـ Use Case
  Future<DashboardStats> execute() async {
    return _repository.getDashboardStats();
  }

  @override
  String toString() => 'GetDashboardStatsUseCase(repository: $_repository)';
}
