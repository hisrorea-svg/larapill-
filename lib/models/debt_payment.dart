/// 💳 نموذج دفعة تسديد دين
class DebtPayment {
  final String id;
  final String customerDebtId; // معرف دين العميل
  final String? saleId; // معرف البيع (إذا كانت الدفعة مرتبطة ببيع)
  final double amount; // المبلغ المدفوع
  final String paymentMethod; // طريقة الدفع (نقداً، بطاقة، إلخ)
  final DateTime paymentDate; // تاريخ الدفع
  final String cashierId; // معرف الكاشير
  final String cashierName; // اسم الكاشير
  final String? notes; // ملاحظات
  final DateTime createdAt;

  DebtPayment({
    required this.id,
    required this.customerDebtId,
    this.saleId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.cashierId,
    required this.cashierName,
    this.notes,
    required this.createdAt,
  });

  /// تحويل من Map إلى Object
  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as String,
      customerDebtId: map['customer_debt_id'] as String,
      saleId: map['sale_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      cashierId: map['cashier_id'] as String,
      cashierName: map['cashier_name'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// تحويل من Object إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_debt_id': customerDebtId,
      'sale_id': saleId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// نسخ مع تعديل
  DebtPayment copyWith({
    String? id,
    String? customerDebtId,
    String? saleId,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? cashierId,
    String? cashierName,
    String? notes,
    DateTime? createdAt,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      customerDebtId: customerDebtId ?? this.customerDebtId,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DebtPayment(id: $id, amount: $amount, date: $paymentDate)';
  }
}
