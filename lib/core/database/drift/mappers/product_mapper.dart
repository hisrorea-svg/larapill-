/// Product Mapper - Converts between Drift entities and Domain models
///
/// This mapper handles the conversion between:
/// - ProductEntry (Drift database entity)
/// - Product (Domain model used in UI)
library product_mapper;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/models/shared/product.dart';
import '../../../../../core/models/shared/medicine_unit.dart';

/// Mapper for Product <-> ProductEntry conversions
class ProductMapper {
  /// Convert ProductEntry (Drift) to Product (Domain)
  static Product fromEntry(ProductEntry entry, List<ProductUnitEntry> units) {
    // Parse base unit with null/empty check
    final baseUnitName = entry.baseUnit.trim().toLowerCase();
    final baseUnit = MedicineUnit.values.firstWhere(
      (u) => u.name.toLowerCase() == baseUnitName,
      orElse: () => MedicineUnit.box, // default to box
    );

    // Build unit info map from ProductUnits
    final Map<MedicineUnit, UnitInfo> unitInfoMap = {};
    for (final unit in units) {
      // Skip units with null/empty unit name
      if (unit.unit.isEmpty) continue;

      final unitName = unit.unit.trim().toLowerCase();
      final medicineUnit = MedicineUnit.values.firstWhere(
        (u) => u.name.toLowerCase() == unitName,
        orElse: () => MedicineUnit.box,
      );

      // Ensure conversionToBase is valid (at least 1)
      final conversion =
          unit.conversionToBase > 0 ? unit.conversionToBase : 1.0;

      unitInfoMap[medicineUnit] = UnitInfo(
        costPrice: unit.costPrice,
        sellingPrice: unit.sellingPrice,
        conversionToBase: conversion,
        description: medicineUnit.arabicName,
      );
    }

    // If no units found, create default from base unit
    if (unitInfoMap.isEmpty) {
      unitInfoMap[baseUnit] = UnitInfo(
        costPrice: 0,
        sellingPrice: 0,
        conversionToBase: 1,
        description: baseUnit.arabicName,
      );
    }

    return Product(
      id: entry.id,
      name: entry.name,
      scientificName: entry.scientificName,
      company: entry.company,
      barcode: entry.barcode,
      expiryDate: entry.expiryDate,
      productionDate: entry.productionDate,
      baseUnit: baseUnit,
      unitInfo: unitInfoMap,
      currentStock: entry.currentStock,
      minStockLevel: entry.minStockLevel,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Convert Product (Domain) to ProductsCompanion (Drift insert/update)
  static ProductsCompanion toCompanion(Product product) {
    return ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      scientificName: Value(product.scientificName),
      company: Value(product.company),
      category: const Value('general'), // default category
      barcode: Value(product.barcode),
      expiryDate: Value(product.expiryDate),
      productionDate: Value(product.productionDate),
      baseUnit: Value(product.baseUnit.name),
      currentStock: Value(product.currentStock),
      minStockLevel: Value(product.minStockLevel),
      isActive: Value(product.isActive),
      createdAt: Value(product.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  static List<ProductUnitsCompanion> toUnitCompanions(
    String productId,
    Map<MedicineUnit, UnitInfo> unitInfo,
  ) {
    return unitInfo.entries.map((entry) {
      return ProductUnitsCompanion(
        id: Value('${productId}_${entry.key.name}'),
        productId: Value(productId),
        unit: Value(entry.key.name),
        costPrice: Value(entry.value.costPrice),
        sellingPrice: Value(entry.value.sellingPrice),
        conversionToBase: Value(entry.value.conversionToBase),
        description:
            Value(entry.value.description), // ✅ ADDED - required field!
      );
    }).toList();
  }
}

/// Extension for convenient conversion
extension ProductEntryExtension on ProductEntry {
  /// Convert to domain Product (without units - use mapper for full conversion)
  Product toProductBasic() {
    return ProductMapper.fromEntry(this, []);
  }
}
