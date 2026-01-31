part of '../app_database.dart';

/// جدول إعدادات النظام
/// System settings table (key-value store)
@DataClassName('SystemSettingEntry')
class SystemSettings extends Table {
  /// المفتاح (Primary Key)
  TextColumn get key => text()();

  /// القيمة
  TextColumn get value => text()();

  /// الوصف
  TextColumn get description => text().nullable()();

  /// التصنيف
  TextColumn get category => text().withDefault(const Constant('general'))();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
