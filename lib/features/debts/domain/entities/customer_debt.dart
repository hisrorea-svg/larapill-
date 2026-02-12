import 'debt_status.dart';

/// 💰 نموذج دين العميل
class CustomerDebt {
  final String id;
  final String customerName;
  final String? customerPhone;
  final double totalDebt; // إجمالي الديون
  final double totalPaid; // إجمالي المدفوع
  final double remainingDebt; // الدين المتبقي
  final int salesCount; // عدد المبيعات
  final DateTime lastTransactionDate; // آخر معاملة
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerDebt({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.totalDebt,
    required this.totalPaid,
    required this.remainingDebt,
    required this.salesCount,
    required this.lastTransactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تحويل من Map إلى Object
  factory CustomerDebt.fromMap(Map<String, dynamic> map) {
    return CustomerDebt(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      totalDebt: (map['total_debt'] as num).toDouble(),
      totalPaid: (map['total_paid'] as num).toDouble(),
      remainingDebt: (map['remaining_debt'] as num).toDouble(),
      salesCount: map['sales_count'] as int,
      lastTransactionDate:
          DateTime.parse(map['last_transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// تحويل من Object إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_debt': totalDebt,
      'total_paid': totalPaid,
      'remaining_debt': remainingDebt,
      'sales_count': salesCount,
      'last_transaction_date': lastTransactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخ مع تعديل
  CustomerDebt copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    double? totalDebt,
    double? totalPaid,
    double? remainingDebt,
    int? salesCount,
    DateTime? lastTransactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerDebt(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      salesCount: salesCount ?? this.salesCount,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// هل العميل مدين حالياً؟
  bool get hasDebt => remainingDebt > 0;

  /// نسبة التسديد
  double get paymentPercentage {
    if (totalDebt == 0) return 100.0;
    return (totalPaid / totalDebt) * 100;
  }

  /// عمر الدين بالأيام (منذ آخر معاملة)
  int get debtAgeDays {
    return DateTime.now().difference(lastTransactionDate).inDays;
  }

  /// حالة الدين بناءً على عمره
  DebtStatus get status {
    if (debtAgeDays >= DebtThresholds.overdueDays) {
      return DebtStatus.overdue;
    } else if (debtAgeDays >= DebtThresholds.warningDays) {
      return DebtStatus.warning;
    }
    return DebtStatus.normal;
  }

  /// هل الدين متأخر؟
  bool get isOverdue => status == DebtStatus.overdue;

  /// هل الدين قريب من التأخير؟
  bool get isWarning => status == DebtStatus.warning;

  @override
  String toString() {
    return 'CustomerDebt(id: $id, name: $customerName, remaining: $remainingDebt)';
  }
}
