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
