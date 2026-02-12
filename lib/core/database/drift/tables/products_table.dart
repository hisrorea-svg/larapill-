part of '../app_database.dart';

/// جدول المنتجات
/// Products table - Core inventory table
@DataClassName('ProductEntry')
class Products extends Table {
  /// معرف فريد UUID
  TextColumn get id => text()();

  /// اسم المنتج
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// الاسم العلمي
  TextColumn get scientificName => text().nullable()();

  /// الشركة المصنعة
  TextColumn get company => text()();

  /// التصنيف
  TextColumn get category => text()();

  /// الباركود - فريد
  TextColumn get barcode => text().unique()();

  /// تاريخ انتهاء الصلاحية
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// تاريخ الإنتاج
  DateTimeColumn get productionDate => dateTime().nullable()();

  /// الوحدة الأساسية
  TextColumn get baseUnit => text()();

  /// المخزون الحالي
  RealColumn get currentStock => real().withDefault(const Constant(0))();

  /// الحد الأدنى للمخزون
  RealColumn get minStockLevel => real().withDefault(const Constant(0))();

  /// هل المنتج نشط
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 🗑️ Soft Delete - هل المنتج محذوف
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 🗑️ تاريخ الحذف
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// تاريخ الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// تاريخ التحديث
  DateTimeColumn get updatedAt => dateTime()();

  /// 👤 من أنشأ السجل
  TextColumn get createdBy => text().nullable()();

  /// 👤 من عدّل السجل آخر مرة
  TextColumn get updatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
