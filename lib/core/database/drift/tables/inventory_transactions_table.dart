part of '../app_database.dart';

/// جدول حركات المخزون - Inventory Transactions
/// يسجل كل حركة مخزون (إضافة، خصم، تعديل)
@DataClassName('InventoryTransactionEntry')
class InventoryTransactions extends Table {
  /// معرف فريد للحركة
  TextColumn get id => text()();

  /// معرف المنتج المرتبط
  TextColumn get productId => text().references(Products, #id)();

  /// نوع الحركة: IN (إضافة), OUT (خصم), ADJUSTMENT (تعديل يدوي)
  TextColumn get type => text()();

  /// الكمية (موجبة للإضافة، سالبة للخصم)
  /// بالوحدة الأساسية للمنتج
  RealColumn get quantity => real()();

  /// معرف المرجع (رقم البيع، رقم الشراء، إلخ)
  TextColumn get referenceId => text().nullable()();

  /// نوع المرجع: sale, purchase, adjustment, return, supplier_return
  TextColumn get referenceType => text().nullable()();

  /// ملاحظات عن الحركة
  TextColumn get notes => text().nullable()();

  /// من أجرى الحركة
  TextColumn get createdBy => text().nullable()();

  /// تاريخ الحركة
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
