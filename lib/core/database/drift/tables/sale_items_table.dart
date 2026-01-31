part of '../app_database.dart';

/// جدول عناصر المبيعات
/// Sale items table - Individual items in a sale
@DataClassName('SaleItemEntry')
class SaleItems extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف عملية البيع
  TextColumn get saleId => text().references(Sales, #id)();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// اسم المنتج (مخزّن للسرعة)
  TextColumn get productName => text()();

  /// الوحدة
  TextColumn get unit => text()();

  /// سعر الوحدة
  RealColumn get unitPrice => real()();

  /// الكمية
  RealColumn get quantity => real()();

  /// الإجمالي
  RealColumn get total => real()();

  /// رقم التشغيلة
  TextColumn get batchNumber => text().nullable()();

  /// تاريخ الانتهاء
  DateTimeColumn get expiryDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
