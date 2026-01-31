import 'package:larapill/features/inventory/data/models/inventory_stats_model.dart';
import 'package:larapill/features/inventory/data/models/product_model.dart';
import 'package:larapill/features/inventory/domain/entities/add_product_params.dart';
import 'package:larapill/features/inventory/domain/entities/inventory_stats.dart';
import 'package:larapill/features/inventory/domain/entities/product_entity.dart';

/// Test data factory for inventory tests
class TestData {
  TestData._();

  // ============ Product Models ============

  static ProductModel createProductModel({
    String? id,
    String name = 'Test Product',
    String? scientificName,
    String company = 'Test Company',
    String category = 'Tablets',
    String barcode = '1234567890123',
    String baseUnit = 'piece',
    double currentStock = 100.0,
    double minStockLevel = 10.0,
    String? expiryDate,
    String? productionDate,
    String? createdAt,
    String? updatedAt,
    int isActive = 1,
    double? sellingPrice = 50.0,
    double? costPrice = 30.0,
  }) {
    return ProductModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      scientificName: scientificName,
      company: company,
      category: category,
      barcode: barcode,
      baseUnit: baseUnit,
      currentStock: currentStock,
      minStockLevel: minStockLevel,
      expiryDate: expiryDate ??
          DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      productionDate: productionDate,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      isActive: isActive,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
    );
  }

  static List<ProductModel> createProductModels(int count) {
    return List.generate(
      count,
      (index) => createProductModel(
        id: 'product_$index',
        name: 'Product $index',
        barcode: 'barcode_$index',
        currentStock: (index + 1) * 10.0,
        sellingPrice: (index + 1) * 5.0,
        costPrice: (index + 1) * 3.0,
      ),
    );
  }

  // ============ Product Entities ============

  static ProductEntity createProductEntity({
    int? id,
    String name = 'Test Product',
    String company = 'Test Company',
    String category = 'Tablets',
    String barcode = '1234567890123',
    int quantity = 100,
    double price = 50.0,
    double? costPrice = 30.0,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isSynced = false,
  }) {
    return ProductEntity(
      id: id ?? DateTime.now().millisecondsSinceEpoch,
      name: name,
      company: company,
      category: category,
      barcode: barcode,
      quantity: quantity,
      price: price,
      costPrice: costPrice,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced,
    );
  }

  static List<ProductEntity> createProductEntities(int count) {
    return List.generate(
      count,
      (index) => createProductEntity(
        id: index + 1,
        name: 'Product $index',
        barcode: 'barcode_$index',
        quantity: (index + 1) * 10,
        price: (index + 1) * 5.0,
        costPrice: (index + 1) * 3.0,
      ),
    );
  }

  // ============ AddProductParams ============

  static AddProductParams createAddProductParams({
    String name = 'New Product',
    String company = 'Test Company',
    String barcode = '9876543210987',
    int quantity = 50,
    double price = 25.0,
    double cost = 15.0,
    DateTime? expiryDate,
    int boxCount = 5,
    int unitsPerBox = 10,
    double boxCost = 150.0,
    double boxPrice = 250.0,
  }) {
    return AddProductParams(
      name: name,
      company: company,
      barcode: barcode,
      quantity: quantity,
      price: price,
      cost: cost,
      expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      boxCount: boxCount,
      unitsPerBox: unitsPerBox,
      boxCost: boxCost,
      boxPrice: boxPrice,
    );
  }

  // ============ Inventory Stats ============

  static InventoryStatsModel createInventoryStatsModel({
    int totalProducts = 100,
    int lowStockCount = 10,
    int criticalStockCount = 5,
    int outOfStockCount = 2,
    int expiredCount = 3,
    int expiringSoonCount = 8,
    double inventoryValue = 50000.0,
    double totalCost = 30000.0,
    double expectedProfit = 20000.0,
    int pendingSyncCount = 0,
  }) {
    return InventoryStatsModel(
      totalProducts: totalProducts,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      outOfStockCount: outOfStockCount,
      expiredCount: expiredCount,
      expiringSoonCount: expiringSoonCount,
      inventoryValue: inventoryValue,
      totalCost: totalCost,
      expectedProfit: expectedProfit,
      pendingSyncCount: pendingSyncCount,
    );
  }

  static InventoryStatsEntity createInventoryStatsEntity({
    int totalProducts = 100,
    int lowStockCount = 10,
    int criticalStockCount = 5,
    int outOfStockCount = 2,
    int expiredCount = 3,
    int expiringSoonCount = 8,
    double inventoryValue = 50000.0,
    double totalCost = 30000.0,
    double expectedProfit = 20000.0,
    int pendingSyncCount = 0,
  }) {
    return InventoryStatsEntity(
      totalProducts: totalProducts,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      outOfStockCount: outOfStockCount,
      expiredCount: expiredCount,
      expiringSoonCount: expiringSoonCount,
      inventoryValue: inventoryValue,
      totalCost: totalCost,
      expectedProfit: expectedProfit,
      pendingSyncCount: pendingSyncCount,
    );
  }

  // ============ Edge Cases ============

  static ProductModel createExpiredProduct() {
    return createProductModel(
      name: 'Expired Product',
      expiryDate:
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );
  }

  static ProductModel createExpiringSoonProduct() {
    return createProductModel(
      name: 'Expiring Soon Product',
      expiryDate:
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    );
  }

  static ProductModel createLowStockProduct() {
    return createProductModel(
      name: 'Low Stock Product',
      currentStock: 5.0,
      minStockLevel: 10.0,
    );
  }

  static ProductModel createOutOfStockProduct() {
    return createProductModel(
      name: 'Out of Stock Product',
      currentStock: 0.0,
    );
  }

  static ProductModel createProductWithoutBarcode() {
    return createProductModel(
      name: 'Product Without Barcode',
      barcode: '',
    );
  }
}
