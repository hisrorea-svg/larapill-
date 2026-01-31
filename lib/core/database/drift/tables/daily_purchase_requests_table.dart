part of '../app_database.dart';

/// جدول طلبيات الشراء اليومية
/// Daily purchase requests table
@DataClassName('DailyPurchaseRequestEntry')
class DailyPurchaseRequests extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// اسم المنتج
  TextColumn get productName => text()();

  /// الكمية المطلوبة
  RealColumn get requestedQuantity => real()();

  /// الوحدة
  TextColumn get unit => text().nullable()();

  /// تمت الإضافة تلقائياً
  BoolColumn get autoAdded => boolean().withDefault(const Constant(false))();

  /// اسم المورد
  TextColumn get supplierName => text().nullable()();

  /// التاريخ
  DateTimeColumn get date => dateTime()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
