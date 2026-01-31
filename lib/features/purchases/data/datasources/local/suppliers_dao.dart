import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/database_helper.dart';

/// نموذج المورد للعرض
class SupplierItem {
  final String id;
  final String name;
  final String? phone;
  final String? contactPerson;
  final String paymentType; // cash, weekly, monthly, credit

  const SupplierItem({
    required this.id,
    required this.name,
    this.phone,
    this.contactPerson,
    this.paymentType = 'cash',
  });

  factory SupplierItem.fromMap(Map<String, dynamic> map) {
    return SupplierItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      contactPerson: map['contact_person'] as String?,
      paymentType: map['payment_type'] as String? ?? 'cash',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'contact_person': contactPerson,
      'payment_type': paymentType,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
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

/// DAO للموردين
class SuppliersDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<SupplierItem>> getActiveSuppliers() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'suppliers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((e) => SupplierItem.fromMap(e)).toList();
  }

  Future<SupplierItem?> getSupplierById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SupplierItem.fromMap(result.first);
  }

  Future<void> addSupplier(SupplierItem supplier) async {
    final db = await _dbHelper.database;
    await db.insert('suppliers', supplier.toMap());
  }
}

/// Provider لقائمة الموردين
final suppliersProvider = FutureProvider<List<SupplierItem>>((ref) async {
  final dao = SuppliersDao();
  return dao.getActiveSuppliers();
});
