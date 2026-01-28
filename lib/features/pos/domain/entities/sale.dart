import '../../../models/medicine_unit.dart';

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paidAmount; // 💰 المبلغ المدفوع
  final double remainingAmount; // 💰 المبلغ المتبقي (الدين)
  final PaymentStatus paymentStatus; // 💰 حالة الدفع
  final PaymentMethod paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String cashierId;
  final String cashierName;
  final SaleStatus status;
  final DateTime createdAt;
  final List<String>? returnIds; // معرفات المرتجعات المرتبطة

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    double? paidAmount,
    double? remainingAmount,
    PaymentStatus? paymentStatus,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
    required this.cashierId,
    required this.cashierName,
    required this.status,
    required this.createdAt,
    this.returnIds,
  })  : paidAmount = paidAmount ?? total,
        remainingAmount = remainingAmount ?? 0,
        paymentStatus = paymentStatus ?? PaymentStatus.paid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_status': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'return_ids': returnIds?.join(','),
    };
  }

  /// إنشاء Sale من Map (للـ Sync والتخزين)
  factory Sale.fromMap(Map<String, dynamic> map) {
    // Parse items
    List<SaleItem> parsedItems = [];
    if (map['items'] != null) {
      final itemsList = map['items'] as List;
      parsedItems = itemsList
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // Parse return_ids
    List<String>? returnIds;
    if (map['return_ids'] != null && map['return_ids'].toString().isNotEmpty) {
      returnIds = map['return_ids'].toString().split(',');
    }

    return Sale(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      items: parsedItems,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble(),
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble(),
      paymentStatus: _parsePaymentStatus(map['payment_status']),
      paymentMethod:
          _parsePaymentMethod(map['paymentMethod'] ?? map['payment_method']),
      customerName: map['customerName'] ?? map['customer_name'],
      customerPhone: map['customerPhone'] ?? map['customer_phone'],
      cashierId: map['cashierId'] ?? map['cashier_id'] ?? '',
      cashierName: map['cashierName'] ?? map['cashier_name'] ?? '',
      status: _parseSaleStatus(map['status']),
      createdAt: DateTime.parse(
        map['createdAt'] ??
            map['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      returnIds: returnIds,
    );
  }

  /// Parse PaymentStatus from string
  static PaymentStatus _parsePaymentStatus(dynamic value) {
    if (value == null) return PaymentStatus.paid;
    final name = value.toString();
    return PaymentStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PaymentStatus.paid,
    );
  }

  /// Parse PaymentMethod from string
  static PaymentMethod _parsePaymentMethod(dynamic value) {
    if (value == null) return PaymentMethod.cash;
    final name = value.toString();
    return PaymentMethod.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PaymentMethod.cash,
    );
  }

  /// Parse SaleStatus from string
  static SaleStatus _parseSaleStatus(dynamic value) {
    if (value == null) return SaleStatus.completed;
    final name = value.toString();
    return SaleStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SaleStatus.completed,
    );
  }

  /// هل البيع مدفوع كلياً؟
  bool get isFullyPaid => paymentStatus == PaymentStatus.paid;

  /// هل يوجد دين؟
  bool get hasDebt => remainingAmount > 0;

  /// نسخ مع تعديل
  Sale copyWith({
    String? id,
    DateTime? date,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? cashierId,
    String? cashierName,
    SaleStatus? status,
    DateTime? createdAt,
    List<String>? returnIds,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      returnIds: returnIds ?? this.returnIds,
    );
  }
}

class SaleItem {
  final String id;
  final String productId;
  final String productName;
  final MedicineUnit unit;
  final double unitPrice;
  final double quantity;
  final double total;

  SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  SaleItem copyWith({
    String? id,
    String? productId,
    String? productName,
    MedicineUnit? unit,
    double? unitPrice,
    double? quantity,
    double? total,
  }) {
    return SaleItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'unit': unit.name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'total': total,
    };
  }

  /// إنشاء SaleItem من Map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String? ?? '',
      productId: map['productId'] ?? map['product_id'] ?? '',
      productName: map['productName'] ?? map['product_name'] ?? '',
      unit: _parseUnit(map['unit']),
      unitPrice:
          (map['unitPrice'] ?? map['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Parse MedicineUnit from string
  static MedicineUnit _parseUnit(dynamic value) {
    if (value == null) return MedicineUnit.piece;
    if (value is MedicineUnit) return value;
    final name = value.toString();
    return MedicineUnit.values.firstWhere(
      (e) => e.name == name,
      orElse: () => MedicineUnit.piece,
    );
  }
}

enum PaymentMethod {
  cash('نقداً'),
  card('بطاقة ائتمان'),
  deferred('آجل / دين');

  const PaymentMethod(this.arabicName);
  final String arabicName;
}

/// 💰 حالة الدفع
enum PaymentStatus {
  paid('مدفوع كلياً'),
  partiallyPaid('مدفوع جزئياً'),
  unpaid('غير مدفوع');

  const PaymentStatus(this.arabicName);
  final String arabicName;
}

enum SaleStatus {
  completed('مكتمل'),
  pending('قيد الانتظار'),
  cancelled('ملغي'),
  returned('مرتجع');

  const SaleStatus(this.arabicName);
  final String arabicName;
}
