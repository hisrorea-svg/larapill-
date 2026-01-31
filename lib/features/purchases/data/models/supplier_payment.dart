/// نموذج دفعة المورد
class SupplierPayment {
  final String id;
  final String supplierId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;

  const SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.notes,
    required this.createdAt,
  });

  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
