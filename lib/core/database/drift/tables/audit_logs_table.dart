part of '../app_database.dart';

/// جدول سجل التدقيق
/// Audit logs table
@DataClassName('AuditLogEntry')
class AuditLogs extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// نوع الإجراء
  TextColumn get actionType => text()();

  /// اسم الإجراء
  TextColumn get actionName => text()();

  /// الخطورة (info, warning, critical)
  TextColumn get severity => text()();

  /// معرف المستخدم
  TextColumn get userId => text()();

  /// اسم المستخدم
  TextColumn get userName => text().nullable()();

  /// نوع الكيان
  TextColumn get entityType => text().nullable()();

  /// معرف الكيان
  TextColumn get entityId => text().nullable()();

  /// الوصف
  TextColumn get description => text().nullable()();

  /// البيانات الإضافية (JSON)
  TextColumn get metadata => text().nullable()();

  /// عنوان IP
  TextColumn get ipAddress => text().nullable()();

  /// هل نجح الإجراء
  BoolColumn get isSuccess => boolean().withDefault(const Constant(true))();

  /// رسالة الخطأ
  TextColumn get errorMessage => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
