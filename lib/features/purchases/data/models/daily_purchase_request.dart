/// نموذج طلبية الشراء اليومية البسيطة
/// تحتوي فقط على: اسم المنتج، الكمية، وطريقة الإضافة (تلقائي/يدوي)
class DailyPurchaseRequest {
  final String id;
  final String productId;
  final String productName;
  final double requestedQuantity;
  final String? unit; // الوحدة (باكيت، شريط، علبة) - اختياري
  final bool autoAdded; // true = أضيف تلقائياً عند النفاد، false = يدوي
  final String? supplierName; // اسم المورد (اختياري)
  final DateTime date; // تاريخ الطلبية
  final DateTime createdAt;

  const DailyPurchaseRequest({
    required this.id,
    required this.productId,
    required this.productName,
    required this.requestedQuantity,
    this.unit,
    required this.autoAdded,
    this.supplierName,
    required this.date,
    required this.createdAt,
  });

  // من قاعدة البيانات
  factory DailyPurchaseRequest.fromMap(Map<String, dynamic> map) {
    return DailyPurchaseRequest(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      requestedQuantity: (map['requested_quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      autoAdded: (map['auto_added'] as int) == 1,
      supplierName: map['supplier_name'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // إلى قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'requested_quantity': requestedQuantity,
      'unit': unit,
      'auto_added': autoAdded ? 1 : 0,
      'supplier_name': supplierName,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD فقط
      'created_at': createdAt.toIso8601String(),
    };
  }

  // نسخ مع تعديلات
  DailyPurchaseRequest copyWith({
    String? id,
    String? productId,
    String? productName,
    double? requestedQuantity,
    bool? autoAdded,
    String? supplierName,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return DailyPurchaseRequest(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      autoAdded: autoAdded ?? this.autoAdded,
      supplierName: supplierName ?? this.supplierName,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // للطباعة والعرض
  @override
  String toString() {
    return 'DailyPurchaseRequest(productName: $productName, quantity: $requestedQuantity, auto: $autoAdded)';
  }

  // للمقارنة
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyPurchaseRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
