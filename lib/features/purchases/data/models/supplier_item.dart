/// نموذج المورد للعرض
class SupplierItem {
  final String id;
  final String name;
  final String? phone;
  final String? contactPerson;
  final String paymentType; // cash, weekly, monthly, credit
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierItem({
    required this.id,
    required this.name,
    this.phone,
    this.contactPerson,
    this.paymentType = 'cash',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierItem.fromMap(Map<String, dynamic> map) {
    return SupplierItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      contactPerson: map['contact_person'] as String?,
      paymentType: map['payment_type'] as String? ?? 'cash',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'contact_person': contactPerson,
      'payment_type': paymentType,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get paymentTypeLabel {
    switch (paymentType) {
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      case 'credit':
        return 'آجل';
      default:
        return 'نقد';
    }
  }
}
