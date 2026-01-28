import 'medicine_unit.dart';

class Product {
  final String id;
  final String name;
  final String? scientificName;
  final String company;
  final String barcode;
  final DateTime? expiryDate;
  final DateTime? productionDate;
  final MedicineUnit baseUnit;
  final Map<MedicineUnit, UnitInfo> unitInfo;
  final double currentStock;
  final double minStockLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.scientificName,
    required this.company,
    required this.barcode,
    this.expiryDate,
    this.productionDate,
    required this.baseUnit,
    required this.unitInfo,
    required this.currentStock,
    required this.minStockLevel,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double getPriceByUnit(MedicineUnit unit) {
    return unitInfo[unit]?.sellingPrice ?? 0.0;
  }

  double getCostPriceByUnit(MedicineUnit unit) {
    return unitInfo[unit]?.costPrice ?? 0.0;
  }

  bool isLowStock() {
    return currentStock <= minStockLevel;
  }

  bool isNearExpiry({int daysThreshold = 30}) {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference <= daysThreshold && difference >= 0;
  }

  bool isExpired() {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// 📊 عرض المخزون بصيغة واضحة (شريط + باكيت)
  String getStockDisplay() {
    // إذا المنتج له وحدة واحدة فقط
    if (unitInfo.length == 1) {
      return '${currentStock.toInt()} ${baseUnit.arabicName}';
    }

    // إذا له وحدتين (مثال: شريط + باكيت)
    final higherUnit = unitInfo.keys.firstWhere(
      (u) => u != baseUnit,
      orElse: () => baseUnit,
    );

    if (higherUnit == baseUnit) {
      return '${currentStock.toInt()} ${baseUnit.arabicName}';
    }

    final higherUnitInfo = unitInfo[higherUnit]!;
    final boxes = currentStock ~/ higherUnitInfo.conversionToBase;
    final remaining = currentStock % higherUnitInfo.conversionToBase.toInt();

    if (remaining == 0) {
      return '$boxes ${higherUnit.arabicName}';
    }

    return '$boxes ${higherUnit.arabicName} + $remaining ${baseUnit.arabicName}';
  }

  /// ✅ التحقق من وجود كمية كافية لبيع وحدة معينة
  bool hasEnoughStock(MedicineUnit unit, double quantity) {
    final info = unitInfo[unit];
    if (info == null) return false;

    final needed = quantity * info.conversionToBase;
    return currentStock >= needed;
  }

  Product copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? company,
    String? barcode,
    DateTime? expiryDate,
    DateTime? productionDate,
    MedicineUnit? baseUnit,
    Map<MedicineUnit, UnitInfo>? unitInfo,
    double? currentStock,
    double? minStockLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      company: company ?? this.company,
      barcode: barcode ?? this.barcode,
      expiryDate: expiryDate ?? this.expiryDate,
      productionDate: productionDate ?? this.productionDate,
      baseUnit: baseUnit ?? this.baseUnit,
      unitInfo: unitInfo ?? this.unitInfo,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'company': company,
      'barcode': barcode,
      'expiryDate': expiryDate?.toIso8601String(),
      'productionDate': productionDate?.toIso8601String(),
      'baseUnit': baseUnit.name,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, company: $company, currentStock: $currentStock)';
  }
}
