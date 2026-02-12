part of '../app_database.dart';

/// جدول نشاطات المستخدمين
/// User Activities table for tracking user actions
@DataClassName('UserActivityEntry')
class UserActivities extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// معرف المستخدم
  TextColumn get userId => text().references(Users, #id)();

  /// نوع النشاط (login, logout, create_user, etc.)
  TextColumn get action => text()();

  /// تفاصيل النشاط
  TextColumn get details => text().nullable()();

  /// عنوان IP
  TextColumn get ipAddress => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
