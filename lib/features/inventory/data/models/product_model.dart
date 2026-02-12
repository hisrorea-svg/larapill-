/// Product Data Transfer Object (DTO) for data layer
/// Handles JSON serialization and database mapping
///
/// NOTE: This model matches the ACTUAL database schema with:
/// - id: TEXT (not int)
/// - current_stock: REAL (instead of quantity)
/// - Prices stored in product_units table (joined via query)
class ProductModel {
  final String id;
  final String name;
  final String? scientificName;
  final String company;
  final String category;
  final String barcode;
  final String baseUnit;
  final double currentStock;
  final double minStockLevel;
  final String? expiryDate;
  final String? productionDate;
  final String? createdAt;
  final String? updatedAt;
  final int isActive;

  // From product_units table (joined)
  final double? sellingPrice;
  final double? costPrice;

  const ProductModel({
    required this.id,
    required this.name,
    this.scientificName,
    required this.company,
    required this.category,
    required this.barcode,
    required this.baseUnit,
    required this.currentStock,
    this.minStockLevel = 10.0,
    this.expiryDate,
    this.productionDate,
    this.createdAt,
    this.updatedAt,
    this.isActive = 1,
    this.sellingPrice,
    this.costPrice,
  });

  /// Create from JSON map (for API responses)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      scientificName: json['scientific_name'] as String?,
      company: json['company'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      baseUnit: json['base_unit'] as String? ?? 'piece',
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble() ?? 10.0,
      expiryDate: json['expiry_date'] as String?,
      productionDate: json['production_date'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isActive: (json['is_active'] as num?)?.toInt() ?? 1,
      sellingPrice: (json['selling_price'] as num?)?.toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON map (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'company': company,
      'category': category,
      'barcode': barcode,
      'base_unit': baseUnit,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'expiry_date': expiryDate,
      'production_date': productionDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
    };
  }

  /// Create from SQLite row (joined query with product_units)
  factory ProductModel.fromSqlite(Map<String, dynamic> row) {
    // Helper to convert date from various formats
    String? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is DateTime) return value.toIso8601String();
      if (value is int) {
        // Drift stores DateTime as milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
      }
      return null;
    }

    return ProductModel(
      id: row['id']?.toString() ?? '',
      name: row['name'] as String? ?? '',
      scientificName: row['scientific_name'] as String?,
      company: row['company'] as String? ?? '',
      category: row['category'] as String? ?? '',
      barcode: row['barcode'] as String? ?? '',
      baseUnit: row['base_unit'] as String? ?? 'piece',
      currentStock: (row['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (row['min_stock_level'] as num?)?.toDouble() ?? 10.0,
      expiryDate: parseDate(row['expiry_date']),
      productionDate: parseDate(row['production_date']),
      createdAt: parseDate(row['created_at']),
      updatedAt: parseDate(row['updated_at']),
      isActive: (row['is_active'] as num?)?.toInt() ?? 1,
      // From joined product_units
      sellingPrice: (row['selling_price'] as num?)?.toDouble(),
      costPrice: (row['cost_price'] as num?)?.toDouble(),
    );
  }

  /// Convert to SQLite row (products table only)
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'company': company,
      'category': category,
      'barcode': barcode,
      'base_unit': baseUnit,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'expiry_date': expiryDate,
      'production_date': productionDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive,
    };
  }

  /// Create a copy with modified fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? company,
    String? category,
    String? barcode,
    String? baseUnit,
    double? currentStock,
    double? minStockLevel,
    String? expiryDate,
    String? productionDate,
    String? createdAt,
    String? updatedAt,
    int? isActive,
    double? sellingPrice,
    double? costPrice,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      company: company ?? this.company,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      baseUnit: baseUnit ?? this.baseUnit,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      expiryDate: expiryDate ?? this.expiryDate,
      productionDate: productionDate ?? this.productionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
    );
  }

  @override
  String toString() => 'ProductModel(id: $id, name: $name)';
}
