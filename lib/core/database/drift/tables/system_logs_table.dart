part of '../app_database.dart';

/// جدول سجلات النظام
/// System logs table for audit and debugging
@DataClassName('SystemLogEntry')
class SystemLogs extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// مستوى السجل (debug, info, warning, error, fatal)
  TextColumn get level => text()();

  /// فئة السجل (auth, sync, database, network, etc.)
  TextColumn get category => text()();

  /// عنوان/ملخص السجل
  TextColumn get title => text()();

  /// تفاصيل السجل (JSON أو نص)
  TextColumn get details => text().nullable()();

  /// معرف المستخدم (إن وجد)
  TextColumn get userId => text().nullable()();

  /// اسم المستخدم (إن وجد)
  TextColumn get userName => text().nullable()();

  /// IP الجهاز (للتتبع)
  TextColumn get ipAddress => text().nullable()();

  /// معرف الجهاز
  TextColumn get deviceId => text().nullable()();

  /// رمز الخطأ (إن وجد)
  TextColumn get errorCode => text().nullable()();

  /// تتبع الاستثناء (stack trace)
  TextColumn get stackTrace => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// مستويات السجل
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// فئات السجل
enum LogCategory {
  auth,
  sync,
  database,
  network,
  inventory,
  sales,
  purchases,
  settings,
  system,
}
