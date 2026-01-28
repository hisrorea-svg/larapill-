/// Stock status enum for inventory management
/// Used to categorize products based on their stock levels
enum StockStatus {
  /// Stock is critically low (< 10 units)
  critical,

  /// Stock is low but not critical (10-20 units)
  low,

  /// Stock level is normal (> 20 units)
  normal,

  /// Product is out of stock (0 units)
  outOfStock,

  /// Stock is overstocked (> 100 units or custom threshold)
  overstocked;

  /// Get Arabic display name
  String get arabicName {
    switch (this) {
      case StockStatus.critical:
        return 'حرج';
      case StockStatus.low:
        return 'منخفض';
      case StockStatus.normal:
        return 'طبيعي';
      case StockStatus.outOfStock:
        return 'نفذ';
      case StockStatus.overstocked:
        return 'فائض';
    }
  }

  /// Determine stock status from quantity
  static StockStatus fromQuantity(int quantity,
      {int minStock = 10, int lowStock = 20}) {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity < minStock) return StockStatus.critical;
    if (quantity < lowStock) return StockStatus.low;
    if (quantity > 100) return StockStatus.overstocked;
    return StockStatus.normal;
  }
}
