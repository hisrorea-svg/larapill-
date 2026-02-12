part of '../app_database.dart';

/// جدول دفعات الموردين
/// Supplier payments table
@DataClassName('SupplierPaymentEntry')
class SupplierPayments extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المورد
  TextColumn get supplierId => text().references(Suppliers, #id)();

  /// المبلغ
  RealColumn get amount => real()();

  /// طريقة الدفع (cash, bank, check)
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// تاريخ الدفع
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
