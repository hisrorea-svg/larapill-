part of '../app_database.dart';

/// جدول دفتر أستاذ الموردين (الحسابات)
/// Supplier ledger table
@DataClassName('SupplierLedgerData')
class SupplierLedger extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المورد
  TextColumn get supplierId => text().references(Suppliers, #id)();

  /// معرف المرجع (رقم الفاتورة، رقم الدفعة، رقم المرتجع)
  TextColumn get referenceId => text()();

  /// نوع المرجع (invoice, payment, return)
  TextColumn get referenceType => text()();

  /// المبلغ (موجب للفواتير، سالب للدفعات والمرتجعات)
  RealColumn get amount => real()();

  /// الرصيد بعد هذا القيد
  RealColumn get balanceAfter => real()();

  /// وصف القيد
  TextColumn get description => text()();

  /// تاريخ القيد
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
