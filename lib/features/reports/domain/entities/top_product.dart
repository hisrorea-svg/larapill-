/// كيان المنتج الأكثر مبيعاً
class TopProduct {
  /// معرف المنتج
  final int productId;

  /// اسم المنتج
  final String name;

  /// الكمية المباعة
  final int quantitySold;

  /// إجمالي المبيعات
  final double totalSales;

  /// الترتيب
  final int rank;

  const TopProduct({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.totalSales,
    required this.rank,
  });

  /// شارة الترتيب
  String get rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }
}
