part of '../app_database.dart';

/// جدول دفعات تسديد الديون
/// Debt payments table
@DataClassName('DebtPaymentEntry')
class DebtPayments extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف دين العميل
  TextColumn get customerDebtId => text().references(CustomerDebts, #id)();

  /// معرف عملية البيع (اختياري)
  TextColumn get saleId => text().nullable()();

  /// المبلغ المدفوع
  RealColumn get amount => real()();

  /// طريقة الدفع
  TextColumn get paymentMethod => text()();

  /// تاريخ الدفع
  DateTimeColumn get paymentDate => dateTime()();

  /// معرف الكاشير
  TextColumn get cashierId => text()();

  /// اسم الكاشير
  TextColumn get cashierName => text()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
