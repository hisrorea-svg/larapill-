part of '../app_database.dart';

/// جدول إعدادات الصيدلية
/// Pharmacy settings table
@DataClassName('PharmacySettingEntry')
class PharmacySettings extends Table {
  /// معرف تسلسلي
  IntColumn get id => integer().autoIncrement()();

  /// اسم الصيدلية بالعربي
  TextColumn get nameAr => text()();

  /// اسم الصيدلية بالإنجليزي
  TextColumn get nameEn => text().nullable()();

  /// رقم الترخيص
  TextColumn get licenseNumber => text().nullable()();

  /// الهاتف الأرضي
  TextColumn get phone => text().nullable()();

  /// الجوال
  TextColumn get mobile => text().nullable()();

  /// البريد الإلكتروني
  TextColumn get email => text().nullable()();

  /// الموقع الإلكتروني
  TextColumn get website => text().nullable()();

  /// العنوان
  TextColumn get address => text().nullable()();

  /// المدينة
  TextColumn get city => text().nullable()();

  /// الرقم الضريبي
  TextColumn get taxNumber => text().nullable()();

  /// السجل التجاري
  TextColumn get commercialRegistration => text().nullable()();

  /// مسار الشعار
  TextColumn get logoPath => text().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();
}
