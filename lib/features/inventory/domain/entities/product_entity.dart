import 'package:equatable/equatable.dart';

/// Immutable product entity for the domain layer
/// Uses Equatable for proper value equality in state management
class ProductEntity extends Equatable {
  // ═══ ثوابت العتبات ═══
  static const int expiryWarningDays = 90;
  static const int lowStockThreshold = 20;
  static const int criticalStockThreshold = 10;

  final String id; // ✅ Changed from int to String for UUID support
  final String name;
  final String company;
  final String category;
  final String barcode;
  final int quantity;
  final double price;
  final double? costPrice;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Offline-first: track if this entity is synced with remote
  final bool isSynced;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.company,
    required this.category,
    required this.barcode,
    required this.quantity,
    required this.price,
    this.costPrice,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        company,
        category,
        barcode,
        quantity,
        price,
        costPrice,
        expiryDate,
        createdAt,
        updatedAt,
        isSynced,
      ];

  /// Create a copy with modified fields
  ProductEntity copyWith({
    String? id,
    String? name,
    String? company,
    String? category,
    String? barcode,
    int? quantity,
    double? price,
    double? costPrice,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Check if product is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Check if product is expiring soon (within expiryWarningDays)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: expiryWarningDays));
    return expiryDate!.isAfter(now) && expiryDate!.isBefore(warningDate);
  }

  /// Check if stock is low (< lowStockThreshold)
  bool get isLowStock => quantity > 0 && quantity < lowStockThreshold;

  /// Check if stock is critical (< criticalStockThreshold)
  bool get isCriticalStock => quantity > 0 && quantity < criticalStockThreshold;

  /// Check if out of stock
  bool get isOutOfStock => quantity <= 0;

  /// Calculate profit margin if cost price is available
  double? get profitMargin {
    if (costPrice == null || costPrice! <= 0) return null;
    return ((price - costPrice!) / costPrice!) * 100;
  }

  /// Calculate profit amount if cost price is available
  double? get profitAmount {
    if (costPrice == null) return null;
    return price - costPrice!;
  }

  @override
  String toString() => 'ProductEntity(id: $id, name: $name, qty: $quantity)';
}
