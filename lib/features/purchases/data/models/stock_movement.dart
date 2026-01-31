/// نموذج حركة المخزون
class StockMovement {
  final String id;
  final String productId;
  final String referenceId;
  final String referenceType; // purchase/return/sale/adjustment
  final double quantity;
  final double? costPerUnit;
  final String? notes;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.referenceId,
    required this.referenceType,
    required this.quantity,
    this.costPerUnit,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      referenceId: map['reference_id'] as String,
      referenceType: map['reference_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      costPerUnit: map['cost_per_unit'] != null
          ? (map['cost_per_unit'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// هل هذه الحركة إضافة للمخزون؟
  bool get isIncoming => quantity > 0;

  /// هل هذه الحركة خصم من المخزون؟
  bool get isOutgoing => quantity < 0;
}
