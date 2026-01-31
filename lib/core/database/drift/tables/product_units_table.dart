part of '../app_database.dart';

/// جدول وحدات المنتج والأسعار
/// Product units table with pricing information
@DataClassName('ProductUnitEntry')
class ProductUnits extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المنتج
  TextColumn get productId => text().references(Products, #id)();

  /// الوحدة (علبة، شريط، حبة)
  TextColumn get unit => text()();

  /// سعر البيع
  RealColumn get sellingPrice => real()();

  /// سعر التكلفة
  RealColumn get costPrice => real()();

  /// معامل التحويل للوحدة الأساسية
  RealColumn get conversionToBase => real().withDefault(const Constant(1.0))();

  /// الوصف
  TextColumn get description => text()();

  /// الكمية في الوحدة
  IntColumn get quantity => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {productId, unit}
      ];
}
