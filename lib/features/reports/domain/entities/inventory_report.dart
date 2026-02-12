/// كيان تقرير المخزون
class InventoryReport {
  /// إجمالي عدد المنتجات
  final int totalProducts;

  /// قيمة المخزون الإجمالية
  final double inventoryValue;

  /// عدد المنتجات ذات المخزون المنخفض
  final int lowStockCount;

  /// عدد المنتجات النافذة من المخزون
  final int outOfStockCount;

  /// عدد المنتجات قريبة الانتهاء (خلال 90 يوم)
  final int expiringSoonCount;

  /// عدد المنتجات المنتهية الصلاحية
  final int expiredCount;

  const InventoryReport({
    required this.totalProducts,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });

  /// تقرير فارغ
  factory InventoryReport.empty() {
    return const InventoryReport(
      totalProducts: 0,
      inventoryValue: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
    );
  }

  /// نسبة المنتجات الفعالة (ليست منخفضة أو نافذة)
  double get healthyStockPercentage {
    if (totalProducts == 0) return 100;
    final problemCount = lowStockCount + outOfStockCount;
    return ((totalProducts - problemCount) / totalProducts) * 100;
  }

  /// هل يوجد تنبيهات؟
  bool get hasAlerts =>
      lowStockCount > 0 || outOfStockCount > 0 || expiringSoonCount > 0;
}
