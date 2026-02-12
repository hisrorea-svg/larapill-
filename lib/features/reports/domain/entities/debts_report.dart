/// كيان تقرير الديون
class DebtsReport {
  /// إجمالي الديون المستحقة
  final double totalDebts;

  /// عدد المدينين
  final int debtorsCount;

  /// إجمالي المبالغ المحصّلة
  final double totalCollected;

  /// عدد الديون المتأخرة (أكثر من 30 يوم)
  final int overdueCount;

  /// قيمة الديون المتأخرة
  final double overdueValue;

  const DebtsReport({
    required this.totalDebts,
    required this.debtorsCount,
    required this.totalCollected,
    required this.overdueCount,
    required this.overdueValue,
  });

  /// تقرير فارغ
  factory DebtsReport.empty() {
    return const DebtsReport(
      totalDebts: 0,
      debtorsCount: 0,
      totalCollected: 0,
      overdueCount: 0,
      overdueValue: 0,
    );
  }

  /// نسبة التحصيل
  double get collectionRate {
    final total = totalDebts + totalCollected;
    if (total == 0) return 100;
    return (totalCollected / total) * 100;
  }

  /// هل يوجد ديون متأخرة؟
  bool get hasOverdue => overdueCount > 0;
}
