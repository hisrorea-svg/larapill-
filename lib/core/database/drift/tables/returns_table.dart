part of '../app_database.dart';

/// جدول المرتجعات
/// Returns table
@DataClassName('ReturnEntry')
class Returns extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف عملية البيع
  TextColumn get saleId => text().references(Sales, #id)();

  /// تاريخ الإرجاع
  DateTimeColumn get returnDate => dateTime()();

  /// السبب
  TextColumn get reason => text()();

  /// الحالة (pending, approved, rejected)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// مبلغ الاسترداد
  RealColumn get totalRefund => real()();

  /// طريقة الاسترداد
  TextColumn get refundMethod => text()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// معرف المعالج
  TextColumn get processedBy => text()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
