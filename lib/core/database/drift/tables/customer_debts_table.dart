part of '../app_database.dart';

/// جدول ديون العملاء
/// Customer debts table
@DataClassName('CustomerDebtEntry')
class CustomerDebts extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// اسم العميل
  TextColumn get customerName => text()();

  /// هاتف العميل
  TextColumn get customerPhone => text().nullable()();

  /// مجموع الديون
  RealColumn get totalDebt => real().withDefault(const Constant(0))();

  /// مجموع المدفوع
  RealColumn get totalPaid => real().withDefault(const Constant(0))();

  /// الديون المتبقية
  RealColumn get remainingDebt => real().withDefault(const Constant(0))();

  /// عدد عمليات البيع
  IntColumn get salesCount => integer().withDefault(const Constant(0))();

  /// تاريخ آخر معاملة
  DateTimeColumn get lastTransactionDate => dateTime()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
