import 'dart:convert';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/entities/notification_priority.dart';

/// نموذج بيانات الإشعار - Data Layer
/// يمتد من Entity ويضيف التسلسل من/إلى قاعدة البيانات
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.priority,
    super.isRead,
    required super.createdAt,
    super.actionData,
    super.userId,
  });

  /// إنشاء من Entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      priority: entity.priority,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      actionData: entity.actionData,
      userId: entity.userId,
    );
  }

  /// إنشاء من Map (قاعدة البيانات) - مع معالجة آمنة للأخطاء
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    try {
      // Parse action data safely
      Map<String, dynamic>? parsedActionData;
      if (map['action_data'] != null && map['action_data'] is String) {
        try {
          parsedActionData =
              jsonDecode(map['action_data'] as String) as Map<String, dynamic>?;
        } catch (e) {
          // If JSON parsing fails, ignore action data
          parsedActionData = null;
        }
      }

      return NotificationModel(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        type: NotificationType.fromString(map['type']?.toString() ?? 'system'),
        priority: NotificationPriority.fromString(
            map['priority']?.toString() ?? 'medium'),
        isRead: (map['is_read'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        actionData: parsedActionData,
        userId: map['user_id']?.toString(),
      );
    } catch (e) {
      // في حالة فشل التحليل، نرجع إشعار فارغ
      return NotificationModel.empty();
    }
  }

  /// محاولة آمنة للتحليل - ترجع null في حالة الفشل
  static NotificationModel? fromMapSafe(Map<String, dynamic> map) {
    try {
      return NotificationModel.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// تحويل إلى Map (لقاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.englishName,
      'priority': priority.englishName,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'action_data': actionData != null ? jsonEncode(actionData) : null,
      'user_id': userId,
    };
  }

  /// إنشاء إشعار فارغ (للحالات الاستثنائية)
  factory NotificationModel.empty() {
    return NotificationModel(
      id: '',
      title: 'خطأ',
      body: 'حدث خطأ في تحميل الإشعار',
      type: NotificationType.system,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
    );
  }

  /// نسخ مع تعديل
  @override
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? actionData,
    String? userId,
  }) {
    return NotificationModel(
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
