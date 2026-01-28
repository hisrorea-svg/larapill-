/// Inventory statistics Data Transfer Object
class InventoryStatsModel {
  final int totalProducts;
  final int lowStockCount;
  final int criticalStockCount;
  final int outOfStockCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double inventoryValue;
  final double totalCost;
  final double expectedProfit;
  final int pendingSyncCount;

  const InventoryStatsModel({
    required this.totalProducts,
    required this.lowStockCount,
    required this.criticalStockCount,
    required this.outOfStockCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.inventoryValue,
    required this.totalCost,
    required this.expectedProfit,
    this.pendingSyncCount = 0,
  });

  /// Create from JSON map
  factory InventoryStatsModel.fromJson(Map<String, dynamic> json) {
    return InventoryStatsModel(
      totalProducts: json['total_products'] as int? ?? 0,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      criticalStockCount: json['critical_stock_count'] as int? ?? 0,
      outOfStockCount: json['out_of_stock_count'] as int? ?? 0,
      expiredCount: json['expired_count'] as int? ?? 0,
      expiringSoonCount: json['expiring_soon_count'] as int? ?? 0,
      inventoryValue: (json['inventory_value'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      expectedProfit: (json['expected_profit'] as num?)?.toDouble() ?? 0.0,
      pendingSyncCount: json['pending_sync_count'] as int? ?? 0,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'critical_stock_count': criticalStockCount,
      'out_of_stock_count': outOfStockCount,
      'expired_count': expiredCount,
      'expiring_soon_count': expiringSoonCount,
      'inventory_value': inventoryValue,
      'total_cost': totalCost,
      'expected_profit': expectedProfit,
      'pending_sync_count': pendingSyncCount,
    };
  }

  /// Create empty stats
  const InventoryStatsModel.empty()
      : totalProducts = 0,
        lowStockCount = 0,
        criticalStockCount = 0,
        outOfStockCount = 0,
        expiredCount = 0,
        expiringSoonCount = 0,
        inventoryValue = 0,
        totalCost = 0,
        expectedProfit = 0,
        pendingSyncCount = 0;
}
