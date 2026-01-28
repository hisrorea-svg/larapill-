/// نوع الإشعار
enum NotificationType {
  system('نظام', 'system', '🔧'),
  inventory('مخزون', 'inventory', '📦'),
  sales('مبيعات', 'sales', '💰'),
  purchases('مشتريات', 'purchases', '🛒'),
  user('مستخدم', 'user', '👤'),
  reminder('تذكير', 'reminder', '⏰');

  const NotificationType(this.arabicName, this.englishName, this.icon);
  final String arabicName;
  final String englishName;
  final String icon;

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.englishName == type,
      orElse: () => NotificationType.system,
    );
  }
}
