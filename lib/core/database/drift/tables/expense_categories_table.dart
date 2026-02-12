part of '../app_database.dart';

/// جدول فئات المصروفات
/// Expense categories table - user-defined categories
@DataClassName('ExpenseCategoryEntry')
class ExpenseCategories extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// اسم الفئة (مثل: إيجار، رواتب)
  TextColumn get name => text()();

  /// أيقونة الفئة (codePoint)
  TextColumn get icon => text().withDefault(const Constant('0xe1d5'))();

  /// لون الفئة
  IntColumn get color => integer().withDefault(const Constant(0xFF5BA3A3))();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
