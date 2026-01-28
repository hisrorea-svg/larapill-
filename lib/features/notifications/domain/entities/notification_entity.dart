import 'package:flutter/foundation.dart';
import 'notification_type.dart';
import 'notification_priority.dart';

/// كيان الإشعار النقي - طبقة Domain
/// لا يعتمد على Flutter أو طبقة البيانات
@immutable
class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? actionData;
  final String? userId;

  const NotificationEntity({
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

  /// نسخ مع تعديل
  NotificationEntity copyWith({
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
    return NotificationEntity(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationEntity &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.priority == priority &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        type.hashCode ^
        priority.hashCode ^
        isRead.hashCode ^
        createdAt.hashCode ^
        userId.hashCode;
  }
}
