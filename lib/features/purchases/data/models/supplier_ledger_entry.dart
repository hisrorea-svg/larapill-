/// نموذج دفتر أستاذ المورد
class SupplierLedgerEntry {
  final String id;
  final String supplierId;
  final String referenceId;
  final String referenceType; // invoice/payment/return/discount
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  const SupplierLedgerEntry({
    required this.id,
    required this.supplierId,
    required this.referenceId,
    required this.referenceType,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  factory SupplierLedgerEntry.fromMap(Map<String, dynamic> map) {
    return SupplierLedgerEntry(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      referenceId: map['reference_id'] as String,
      referenceType: map['reference_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      balanceAfter: (map['balance_after'] as num).toDouble(),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'amount': amount,
      'balance_after': balanceAfter,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// هل هذا القيد دائن (فاتورة جديدة)؟
  bool get isCredit => amount > 0;

  /// هل هذا القيد مدين (دفعة/مرتجع)؟
  bool get isDebit => amount < 0;
}
