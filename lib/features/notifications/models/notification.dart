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

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final String? actionData; // JSON data for action
  final String? userId; // null for system-wide notifications

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.isRead = false,
    required this.createdAt,
    this.actionData,
    this.userId,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.fromString(map['type'] as String),
      priority: NotificationPriority.fromString(map['priority'] as String),
      isRead: (map['is_read'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      actionData: map['action_data'] as String?,
      userId: map['user_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.englishName,
      'priority': priority.englishName,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'action_data': actionData,
      'user_id': userId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    String? actionData,
    String? userId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionData: actionData ?? this.actionData,
      userId: userId ?? this.userId,
    );
  }
}
