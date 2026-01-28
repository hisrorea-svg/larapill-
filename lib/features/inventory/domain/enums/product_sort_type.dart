/// Product sort type enum for inventory list sorting
enum ProductSortType {
  /// Sort by product name alphabetically
  name,

  /// Sort by price
  price,

  /// Sort by stock quantity
  quantity,

  /// Sort by expiry date
  expiry,

  /// Sort by category
  category,

  /// Sort by creation date
  createdAt,

  /// Sort by last update date
  updatedAt;

  /// Get Arabic display name
  String get arabicName {
    switch (this) {
      case ProductSortType.name:
        return 'الاسم';
      case ProductSortType.price:
        return 'السعر';
      case ProductSortType.quantity:
        return 'الكمية';
      case ProductSortType.expiry:
        return 'الصلاحية';
      case ProductSortType.category:
        return 'الفئة';
      case ProductSortType.createdAt:
        return 'تاريخ الإضافة';
      case ProductSortType.updatedAt:
        return 'آخر تحديث';
    }
  }
}
