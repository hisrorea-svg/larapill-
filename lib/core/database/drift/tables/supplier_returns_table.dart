part of '../app_database.dart';

/// جدول مرتجعات الموردين
/// Supplier returns table
@DataClassName('SupplierReturnEntry')
class SupplierReturns extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المورد
  TextColumn get supplierId => text().references(Suppliers, #id)();

  /// معرف الفاتورة الأصلية (اختياري)
  TextColumn get invoiceId =>
      text().nullable().references(PurchaseOrders, #id)();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// الكمية المرتجعة
  RealColumn get quantity => real()();

  /// إجمالي المبلغ المرتجع
  RealColumn get amount => real()();

  /// الحالة (prepared, delivered)
  TextColumn get status => text().withDefault(const Constant('prepared'))();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// تاريخ التسليم للمورد
  DateTimeColumn get deliveredDate => dateTime().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
