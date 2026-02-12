part of '../app_database.dart';

/// جدول جلسات المستخدمين
/// User sessions table
@DataClassName('UserSessionEntry')
class UserSessions extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المستخدم
  TextColumn get userId => text().references(Users, #id)();

  /// رمز الجلسة
  TextColumn get sessionToken => text().unique()();

  /// معلومات الجهاز
  TextColumn get deviceInfo => text().nullable()();

  /// عنوان IP
  TextColumn get ipAddress => text().nullable()();

  /// وقت تسجيل الدخول
  DateTimeColumn get loginTime => dateTime()();

  /// آخر نشاط
  DateTimeColumn get lastActivity => dateTime()();

  /// هل الجلسة نشطة
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// وقت انتهاء الجلسة
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
