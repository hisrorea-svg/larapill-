import 'report_period.dart';

/// كيان التقرير المالي
class FinancialReport {
  /// الفترة الزمنية
  final ReportPeriod period;

  /// إجمالي الإيرادات
  final double totalRevenue;

  /// إجمالي الأرباح
  final double totalProfit;

  /// إجمالي المصروفات
  final double totalExpenses;

  /// إجمالي المشتريات
  final double totalPurchases;

  const FinancialReport({
    required this.period,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalExpenses,
    required this.totalPurchases,
  });

  /// تقرير فارغ
  factory FinancialReport.empty(ReportPeriod period) {
    return FinancialReport(
      period: period,
      totalRevenue: 0,
      totalProfit: 0,
      totalExpenses: 0,
      totalPurchases: 0,
    );
  }

  /// صافي الربح
  double get netProfit => totalProfit - totalExpenses;

  /// نسبة الربح من الإيرادات
  double get profitMargin =>
      totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
}
