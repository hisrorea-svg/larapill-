import '../../../../core/models/shared/medicine_unit.dart';

// أسباب الإرجاع المتاحة
enum ReturnReason {
  defective('منتج معيب'),
  wrongProduct('منتج خاطئ'),
  expiredProduct('منتج منتهي الصلاحية'),
  customerDissatisfaction('عدم رضا العميل'),
  other('سبب آخر');

  const ReturnReason(this.arabicName);
  final String arabicName;
}

// حالات المرتجع
enum ReturnStatus {
  pending('قيد المعالجة'),
  approved('تمت الموافقة'),
  completed('مكتمل'),
  rejected('مرفوض');

  const ReturnStatus(this.arabicName);
  final String arabicName;
}

// طرق استرداد المبلغ
enum RefundMethod {
  cash('نقداً'),
  card('بطاقة ائتمان'),
  storeCredit('رصيد في المتجر');

  const RefundMethod(this.arabicName);
  final String arabicName;
}

// نموذج عنصر المرتجع
class ReturnItem {
  final String id;
  final String productId;
  final String productName;
  final MedicineUnit unit;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? reasonDetails;
  final String? batchNumber;
  final DateTime? expiryDate;

  ReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.reasonDetails,
    this.batchNumber,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'unit': unit.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'reason_details': reasonDetails,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unit: MedicineUnit.values.firstWhere((e) => e.name == map['unit']),
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      reasonDetails: map['reason_details'] as String?,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
    );
  }
}

// نموذج المرتجع الرئيسي
class Return {
  final String id;
  final String saleId;
  final DateTime returnDate;
  final List<ReturnItem> items;
  final ReturnReason reason;
  final ReturnStatus status;
  final double totalRefund;
  final RefundMethod refundMethod;
  final String? notes;
  final String processedBy;
  final DateTime createdAt;

  Return({
    required this.id,
    required this.saleId,
    required this.returnDate,
    required this.items,
    required this.reason,
    required this.status,
    required this.totalRefund,
    required this.refundMethod,
    this.notes,
    required this.processedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'return_date': returnDate.toIso8601String(),
      'reason': reason.name,
      'status': status.name,
      'total_refund': totalRefund,
      'refund_method': refundMethod.name,
      'notes': notes,
      'processed_by': processedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Return.fromMap(Map<String, dynamic> map) {
    return Return(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
      returnDate: DateTime.parse(map['return_date'] as String),
      items: [], // يتم تحميل العناصر بشكل منفصل
      reason: ReturnReason.values.firstWhere((e) => e.name == map['reason']),
      status: ReturnStatus.values.firstWhere((e) => e.name == map['status']),
      totalRefund: (map['total_refund'] as num).toDouble(),
      refundMethod:
          RefundMethod.values.firstWhere((e) => e.name == map['refund_method']),
      notes: map['notes'] as String?,
      processedBy: map['processed_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
