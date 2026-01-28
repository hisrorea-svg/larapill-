import 'package:equatable/equatable.dart';

/// Immutable inventory statistics entity
class InventoryStatsEntity extends Equatable {
  /// Total number of products in inventory
  final int totalProducts;

  /// Number of products with low stock (< 20)
  final int lowStockCount;

  /// Number of products with critical stock (< 10)
  final int criticalStockCount;

  /// Number of out of stock products
  final int outOfStockCount;

  /// Number of expired products
  final int expiredCount;

  /// Number of products expiring soon (within 90 days)
  final int expiringSoonCount;

  /// Total inventory value (quantity * price for all products)
  final double inventoryValue;

  /// Total cost value (quantity * cost for all products)
  final double totalCost;

  /// Expected profit (inventoryValue - totalCost)
  final double expectedProfit;

  /// Number of pending sync operations
  final int pendingSyncCount;

  const InventoryStatsEntity({
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

  /// Create empty stats
  const InventoryStatsEntity.empty()
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

  @override
  List<Object?> get props => [
        totalProducts,
        lowStockCount,
        criticalStockCount,
        outOfStockCount,
        expiredCount,
        expiringSoonCount,
        inventoryValue,
        totalCost,
        expectedProfit,
        pendingSyncCount,
      ];

  /// Calculate profit margin percentage
  double get profitMarginPercent {
    if (totalCost <= 0) return 0;
    return (expectedProfit / totalCost) * 100;
  }

  /// Check if there are any alerts (low stock, expired, etc.)
  bool get hasAlerts =>
      lowStockCount > 0 ||
      criticalStockCount > 0 ||
      expiredCount > 0 ||
      expiringSoonCount > 0;

  /// Total alert count
  int get totalAlerts =>
      lowStockCount + criticalStockCount + expiredCount + expiringSoonCount;

  InventoryStatsEntity copyWith({
    int? totalProducts,
    int? lowStockCount,
    int? criticalStockCount,
    int? outOfStockCount,
    int? expiredCount,
    int? expiringSoonCount,
    double? inventoryValue,
    double? totalCost,
    double? expectedProfit,
    int? pendingSyncCount,
  }) {
    return InventoryStatsEntity(
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      expiredCount: expiredCount ?? this.expiredCount,
      expiringSoonCount: expiringSoonCount ?? this.expiringSoonCount,
      inventoryValue: inventoryValue ?? this.inventoryValue,
      totalCost: totalCost ?? this.totalCost,
      expectedProfit: expectedProfit ?? this.expectedProfit,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}
