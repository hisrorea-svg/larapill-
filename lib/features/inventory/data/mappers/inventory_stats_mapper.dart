import '../../domain/entities/inventory_stats.dart';
import '../models/inventory_stats_model.dart';

/// Mapper for converting between InventoryStatsEntity and InventoryStatsModel
class InventoryStatsMapper {
  InventoryStatsMapper._(); // Private constructor - static methods only

  /// Convert InventoryStatsModel (DTO) to InventoryStatsEntity (Domain)
  static InventoryStatsEntity toEntity(InventoryStatsModel model) {
    return InventoryStatsEntity(
      totalProducts: model.totalProducts,
      lowStockCount: model.lowStockCount,
      criticalStockCount: model.criticalStockCount,
      outOfStockCount: model.outOfStockCount,
      expiredCount: model.expiredCount,
      expiringSoonCount: model.expiringSoonCount,
      inventoryValue: model.inventoryValue,
      totalCost: model.totalCost,
      expectedProfit: model.expectedProfit,
      pendingSyncCount: model.pendingSyncCount,
    );
  }

  /// Convert InventoryStatsEntity (Domain) to InventoryStatsModel (DTO)
  static InventoryStatsModel toModel(InventoryStatsEntity entity) {
    return InventoryStatsModel(
      totalProducts: entity.totalProducts,
      lowStockCount: entity.lowStockCount,
      criticalStockCount: entity.criticalStockCount,
      outOfStockCount: entity.outOfStockCount,
      expiredCount: entity.expiredCount,
      expiringSoonCount: entity.expiringSoonCount,
      inventoryValue: entity.inventoryValue,
      totalCost: entity.totalCost,
      expectedProfit: entity.expectedProfit,
      pendingSyncCount: entity.pendingSyncCount,
    );
  }
}
