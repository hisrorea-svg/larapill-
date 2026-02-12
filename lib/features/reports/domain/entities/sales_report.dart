import 'report_period.dart';

/// كيان تقرير المبيعات
class SalesReport {
  /// الفترة الزمنية
  final ReportPeriod period;

  /// عدد الفواتير
  final int invoiceCount;

  /// إجمالي المبيعات
  final double totalSales;

  /// الربح المتوقع
  final double expectedProfit;

  /// عدد الفواتير النقدية
  final int cashInvoices;

  /// عدد الفواتير الآجلة
  final int creditInvoices;

  /// عدد المرتجعات
  final int returnCount;

  /// قيمة المرتجعات
  final double returnValue;

  const SalesReport({
    required this.period,
    required this.invoiceCount,
    required this.totalSales,
    required this.expectedProfit,
    required this.cashInvoices,
    required this.creditInvoices,
    required this.returnCount,
    required this.returnValue,
  });

  /// تقرير فارغ
  factory SalesReport.empty(ReportPeriod period) {
    return SalesReport(
      period: period,
      invoiceCount: 0,
      totalSales: 0,
      expectedProfit: 0,
      cashInvoices: 0,
      creditInvoices: 0,
      returnCount: 0,
      returnValue: 0,
    );
  }

  /// صافي المبيعات (بعد خصم المرتجعات)
  double get netSales => totalSales - returnValue;

  /// نسبة الربح
  double get profitMargin =>
      totalSales > 0 ? (expectedProfit / totalSales) * 100 : 0;
}
