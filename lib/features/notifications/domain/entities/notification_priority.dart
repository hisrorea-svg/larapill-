/// أولوية الإشعار
enum NotificationPriority {
  low('منخفض', 'low'),
  medium('متوسط', 'medium'),
  high('عالي', 'high'),
  urgent('عاجل', 'urgent');

  const NotificationPriority(this.arabicName, this.englishName);
  final String arabicName;
  final String englishName;

  static NotificationPriority fromString(String priority) {
    return NotificationPriority.values.firstWhere(
      (e) => e.englishName == priority,
      orElse: () => NotificationPriority.medium,
    );
  }
}
