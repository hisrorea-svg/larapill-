part of '../app_database.dart';

/// جدول حركات المخزون
/// Stock movements table
@DataClassName('StockMovementEntry')
class StockMovements extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// معرف المرجع (رقم الفاتورة، رقم المبيعة، إلخ)
  TextColumn get referenceId => text()();

  /// نوع المرجع (purchase, sale, adjustment, supplier_return, return)
  TextColumn get referenceType => text()();

  /// الكمية (موجب للإضافة، سالب للخصم)
  RealColumn get quantity => real()();

  /// التكلفة لكل وحدة في هذه الحركة
  RealColumn get costPerUnit => real().nullable()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// تاريخ الحركة
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
