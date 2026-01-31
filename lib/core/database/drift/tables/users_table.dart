part of '../app_database.dart';

/// جدول المستخدمين
/// Users table
@DataClassName('UserEntry')
class Users extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// اسم المستخدم
  TextColumn get username => text().unique()();

  /// الاسم الكامل
  TextColumn get fullName => text()();

  /// البريد الإلكتروني
  TextColumn get email => text().nullable()();

  /// رقم الهاتف
  TextColumn get phone => text().nullable()();

  /// كلمة المرور المشفرة
  TextColumn get passwordHash => text()();

  /// الدور (admin, cashier, pharmacist)
  TextColumn get role => text().withDefault(const Constant('cashier'))();

  /// الصلاحيات (JSON)
  TextColumn get permissions => text().nullable()();

  /// هل المستخدم نشط
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// إجبار تغيير كلمة المرور
  BoolColumn get forcePasswordChange =>
      boolean().withDefault(const Constant(false))();

  /// آخر تسجيل دخول
  DateTimeColumn get lastLogin => dateTime().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  /// معرف المنشئ
  TextColumn get createdBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
