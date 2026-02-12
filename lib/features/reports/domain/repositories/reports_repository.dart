import '../entities/report_period.dart';
import '../entities/sales_report.dart';
import '../entities/inventory_report.dart';
import '../entities/financial_report.dart';
import '../entities/debts_report.dart';
import '../entities/top_product.dart';

/// واجهة مستودع التقارير
abstract class ReportsRepository {
  /// جلب تقرير المبيعات للفترة المحددة
  Future<SalesReport> getSalesReport(ReportPeriod period);

  /// جلب تقرير المخزون
  Future<InventoryReport> getInventoryReport();

  /// جلب التقرير المالي للفترة المحددة
  Future<FinancialReport> getFinancialReport(ReportPeriod period);

  /// جلب تقرير الديون
  Future<DebtsReport> getDebtsReport();

  /// جلب أفضل المنتجات مبيعاً
  /// [limit] - عدد المنتجات المطلوبة
  /// [period] - الفترة الزمنية
  Future<List<TopProduct>> getTopProducts({
    required int limit,
    required ReportPeriod period,
  });
}
