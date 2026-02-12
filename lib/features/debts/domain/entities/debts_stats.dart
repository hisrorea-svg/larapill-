/// إحصائيات الديون الموسعة
class DebtsStats {
  /// إجمالي الديون المتبقية
  final double totalDebts;

  /// عدد المدينين
  final int debtorsCount;

  /// إجمالي الديون المتأخرة (> 30 يوم)
  final double overdueDebts;

  /// عدد الديون المتأخرة
  final int overdueCount;

  /// المحصّل هذا الشهر
  final double collectedThisMonth;

  /// عدد الدفعات هذا الشهر
  final int paymentsThisMonth;

  const DebtsStats({
    required this.totalDebts,
    required this.debtorsCount,
    required this.overdueDebts,
    required this.overdueCount,
    required this.collectedThisMonth,
    required this.paymentsThisMonth,
  });

  /// إحصائيات فارغة
  factory DebtsStats.empty() {
    return const DebtsStats(
      totalDebts: 0,
      debtorsCount: 0,
      overdueDebts: 0,
      overdueCount: 0,
      collectedThisMonth: 0,
      paymentsThisMonth: 0,
    );
  }

  /// نسبة الديون المتأخرة من الإجمالي
  double get overduePercentage {
    if (totalDebts == 0) return 0;
    return (overdueDebts / totalDebts) * 100;
  }
}
