part of '../app_database.dart';

/// جدول عناصر المرتجعات
/// Return items table
@DataClassName('ReturnItemEntry')
class ReturnItems extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المرتجع
  TextColumn get returnId => text().references(Returns, #id)();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// اسم المنتج
  TextColumn get productName => text()();

  /// الوحدة
  TextColumn get unit => text()();

  /// الكمية
  RealColumn get quantity => real()();

  /// سعر الوحدة
  RealColumn get unitPrice => real()();

  /// الإجمالي
  RealColumn get total => real()();

  /// تفاصيل السبب
  TextColumn get reasonDetails => text().nullable()();

  /// رقم التشغيلة
  TextColumn get batchNumber => text().nullable()();

  /// تاريخ الانتهاء
  DateTimeColumn get expiryDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
