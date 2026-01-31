/// نموذج مرتجع المورد
class SupplierReturn {
  final String id;
  final String supplierId;
  final String? invoiceId;
  final String productId;
  final double quantity;
  final double amount;
  final String status; // prepared/delivered
  final DateTime? deliveredDate;
  final String? notes;
  final DateTime createdAt;

  const SupplierReturn({
    required this.id,
    required this.supplierId,
    this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.amount,
    this.status = 'prepared',
    this.deliveredDate,
    this.notes,
    required this.createdAt,
  });

  factory SupplierReturn.fromMap(Map<String, dynamic> map) {
    return SupplierReturn(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      invoiceId: map['invoice_id'] as String?,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'prepared',
      deliveredDate: map['delivered_date'] != null
          ? DateTime.parse(map['delivered_date'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'amount': amount,
      'status': status,
      'delivered_date': deliveredDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// هل تم تسليم المرتجع؟
  bool get isDelivered => status == 'delivered';

  /// هل المرتجع جاهز للتسليم؟
  bool get isPrepared => status == 'prepared';

  SupplierReturn copyWith({
    String? status,
    DateTime? deliveredDate,
  }) {
    return SupplierReturn(
      id: id,
      supplierId: supplierId,
      invoiceId: invoiceId,
      productId: productId,
      quantity: quantity,
      amount: amount,
      status: status ?? this.status,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
