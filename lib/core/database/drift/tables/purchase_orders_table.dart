part of '../app_database.dart';

/// جدول طلبات الشراء
/// Purchase orders table
@DataClassName('PurchaseOrderEntry')
class PurchaseOrders extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// رقم الطلب
  TextColumn get orderNumber => text().unique()();

  /// معرف المورد
  TextColumn get supplierId => text().references(Suppliers, #id)();

  /// المجموع الفرعي
  RealColumn get subtotal => real().withDefault(const Constant(0))();

  /// الخصم
  RealColumn get discount => real().withDefault(const Constant(0))();

  /// الضريبة
  RealColumn get tax => real().withDefault(const Constant(0))();

  /// الإجمالي
  RealColumn get total => real().withDefault(const Constant(0))();

  /// الحالة (pending, approved, received, cancelled)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// تاريخ الطلب
  DateTimeColumn get orderDate => dateTime()();

  /// تاريخ التسليم المتوقع
  DateTimeColumn get expectedDeliveryDate => dateTime().nullable()();

  /// تاريخ التسليم الفعلي
  DateTimeColumn get actualDeliveryDate => dateTime().nullable()();

  /// تاريخ الترحيل (posted)
  DateTimeColumn get postedAt => dateTime().nullable()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// معرف المنشئ
  TextColumn get createdBy => text()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
