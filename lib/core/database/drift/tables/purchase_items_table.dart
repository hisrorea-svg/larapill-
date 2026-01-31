part of '../app_database.dart';

/// جدول عناصر طلبات الشراء
/// Purchase items table
@DataClassName('PurchaseItemEntry')
class PurchaseItems extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف طلب الشراء
  TextColumn get purchaseOrderId => text().references(PurchaseOrders, #id)();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// اسم المنتج
  TextColumn get productName => text()();

  /// الوحدة
  TextColumn get unit => text()();

  /// الكمية المطلوبة
  RealColumn get quantity => real()();

  /// الكمية المستلمة
  RealColumn get receivedQuantity => real().withDefault(const Constant(0))();

  /// سعر الوحدة
  RealColumn get unitPrice => real()();

  /// الإجمالي
  RealColumn get total => real()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
