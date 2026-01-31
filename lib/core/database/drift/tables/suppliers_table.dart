part of '../app_database.dart';

/// جدول الموردين
/// Suppliers table
@DataClassName('SupplierEntry')
class Suppliers extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// اسم المورد
  TextColumn get name => text()();

  /// مسؤول التواصل
  TextColumn get contactPerson => text().nullable()();

  /// رقم الهاتف
  TextColumn get phone => text().nullable()();

  /// البريد الإلكتروني
  TextColumn get email => text().nullable()();

  /// العنوان
  TextColumn get address => text().nullable()();

  /// ملاحظات
  TextColumn get notes => text().nullable()();

  /// نوع الدفع (cash, weekly, monthly, credit)
  TextColumn get paymentType => text().withDefault(const Constant('cash'))();

  /// هل المورد نشط
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
