part of '../app_database.dart';

/// جدول المصروفات
/// Expenses table - individual expense records
@DataClassName('ExpenseEntry')
class Expenses extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف الفئة
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();

  /// المبلغ
  RealColumn get amount => real()();

  /// تاريخ المصروف
  DateTimeColumn get date => dateTime()();

  /// ملاحظة اختيارية
  TextColumn get note => text().nullable()();

  /// هل هو مصروف متكرر
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  /// يوم التكرار الشهري (1-31)
  IntColumn get recurringDay => integer().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
