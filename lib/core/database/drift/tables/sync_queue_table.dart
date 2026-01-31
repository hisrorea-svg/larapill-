part of '../app_database.dart';

/// جدول قائمة المزامنة
/// Sync queue table for multi-terminal sync
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// الإجراء (insert, update, delete)
  TextColumn get action => text()();

  /// البيانات (JSON)
  TextColumn get payload => text()();

  /// الحالة (0=pending, 1=synced, 2=failed)
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// عدد المحاولات
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// رسالة الخطأ
  TextColumn get errorMessage => text().nullable()();

  /// تاريخ الإنشاء (كـ timestamp)
  IntColumn get createdAt => integer()();

  /// آخر محاولة (كـ timestamp)
  IntColumn get lastAttemptAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
