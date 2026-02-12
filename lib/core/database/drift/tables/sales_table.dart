part of '../app_database.dart';

/// جدول المبيعات
/// Sales table - Main sales transactions
@DataClassName('SaleEntry')
class Sales extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// رقم الفاتورة
  TextColumn get invoiceNumber => text().unique().nullable()();

  /// تاريخ البيع
  DateTimeColumn get date => dateTime()();

  /// المجموع الفرعي
  RealColumn get subtotal => real()();

  /// الخصم
  RealColumn get discount => real().withDefault(const Constant(0))();

  /// الضريبة
  RealColumn get tax => real().withDefault(const Constant(0))();

  /// الإجمالي
  RealColumn get total => real()();

  /// المبلغ المدفوع
  RealColumn get paidAmount => real().withDefault(const Constant(0))();

  /// المبلغ المتبقي
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();

  /// حالة الدفع (paid, partial, unpaid)
  TextColumn get paymentStatus => text().withDefault(const Constant('paid'))();

  /// طريقة الدفع
  TextColumn get paymentMethod => text()();

  /// اسم العميل
  TextColumn get customerName => text().nullable()();

  /// هاتف العميل
  TextColumn get customerPhone => text().nullable()();

  /// معرف الكاشير
  TextColumn get cashierId => text()();

  /// اسم الكاشير
  TextColumn get cashierName => text().nullable()();

  /// حالة البيع (completed, cancelled, refunded)
  TextColumn get status => text().withDefault(const Constant('completed'))();

  /// معرفات المرتجعات (مخزنة كنص مفصول بفاصلة)
  TextColumn get returnIds => text().nullable()();

  /// 🗑️ Soft Delete - هل البيع محذوف
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 🗑️ تاريخ الحذف
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// 👤 من أنشأ السجل
  TextColumn get createdBy => text().nullable()();

  /// 👤 من عدّل السجل آخر مرة
  TextColumn get updatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
