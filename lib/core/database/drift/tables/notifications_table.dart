part of '../app_database.dart';

/// جدول الإشعارات
/// Notifications table
@DataClassName('NotificationEntry')
class Notifications extends Table {
  /// معرف فريد
  TextColumn get id => text()();

  /// العنوان
  TextColumn get title => text()();

  /// المحتوى
  TextColumn get body => text()();

  /// النوع (expiry, low_stock, system)
  TextColumn get type => text()();

  /// الأولوية (low, medium, high, critical)
  TextColumn get priority => text()();

  /// هل تمت القراءة
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// بيانات الإجراء (JSON)
  TextColumn get actionData => text().nullable()();

  /// معرف المستخدم
  TextColumn get userId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
