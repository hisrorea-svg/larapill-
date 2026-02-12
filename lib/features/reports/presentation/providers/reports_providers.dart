import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/inventory_report.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/debts_report.dart';
import '../../domain/entities/top_product.dart';
import '../../data/repositories/reports_repository_impl.dart';

// ============ State Providers ============

/// الفترة المختارة حالياً
final selectedPeriodTypeProvider = StateProvider<ReportPeriodType>((ref) {
  return ReportPeriodType.today;
});

/// تاريخ البداية المخصص
final customStartDateProvider = StateProvider<DateTime?>((ref) => null);

/// تاريخ النهاية المخصص
final customEndDateProvider = StateProvider<DateTime?>((ref) => null);

/// الفترة الزمنية الكاملة بناءً على الاختيار
final selectedPeriodProvider = Provider<ReportPeriod>((ref) {
  final type = ref.watch(selectedPeriodTypeProvider);
  final customStart = ref.watch(customStartDateProvider);
  final customEnd = ref.watch(customEndDateProvider);

  switch (type) {
    case ReportPeriodType.today:
      return ReportPeriod.today();
    case ReportPeriodType.yesterday:
      return ReportPeriod.yesterday();
    case ReportPeriodType.week:
      return ReportPeriod.week();
    case ReportPeriodType.month:
      return ReportPeriod.month();
    case ReportPeriodType.year:
      return ReportPeriod.year();
    case ReportPeriodType.custom:
      if (customStart != null && customEnd != null) {
        return ReportPeriod.custom(customStart, customEnd);
      }
      return ReportPeriod.today();
  }
});

// ============ Data Providers ============

/// تقرير المبيعات
final salesReportProvider = FutureProvider<SalesReport>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getSalesReport(period);
});

/// تقرير المخزون
final inventoryReportProvider = FutureProvider<InventoryReport>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getInventoryReport();
});

/// التقرير المالي
final financialReportProvider = FutureProvider<FinancialReport>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getFinancialReport(period);
});

/// تقرير الديون
final debtsReportProvider = FutureProvider<DebtsReport>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getDebtsReport();
});

/// أفضل المنتجات مبيعاً
final topProductsProvider = FutureProvider<List<TopProduct>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getTopProducts(limit: 10, period: period);
});

// ============ Helper Functions ============

/// تحديث جميع التقارير
void refreshAllReports(WidgetRef ref) {
  ref.invalidate(salesReportProvider);
  ref.invalidate(inventoryReportProvider);
  ref.invalidate(financialReportProvider);
  ref.invalidate(debtsReportProvider);
  ref.invalidate(topProductsProvider);
}
