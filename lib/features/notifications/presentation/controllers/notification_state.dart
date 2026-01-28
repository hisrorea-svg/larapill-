import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';

/// حالة الإشعارات
@immutable
class NotificationState {
  final List<NotificationEntity> notifications;
  final Map<String, List<NotificationEntity>> groupedNotifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.groupedNotifications = const {},
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  /// نسخ مع تعديل
  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    Map<String, List<NotificationEntity>>? groupedNotifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      groupedNotifications: groupedNotifications ?? this.groupedNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// حالة التحميل الأولية
  factory NotificationState.initial() {
    return const NotificationState(isLoading: true);
  }

  /// حالة النجاح
  factory NotificationState.success(List<NotificationEntity> notifications) {
    return NotificationState(
      notifications: notifications,
      groupedNotifications: _groupByDate(notifications),
      unreadCount: notifications.where((n) => !n.isRead).length,
    );
  }

  /// حالة الخطأ
  factory NotificationState.error(String error) {
    return NotificationState(error: error);
  }

  /// تجميع الإشعارات حسب التاريخ
  static Map<String, List<NotificationEntity>> _groupByDate(
    List<NotificationEntity> notifications,
  ) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <NotificationEntity>[];
    final yesterdayList = <NotificationEntity>[];
    final olderList = <NotificationEntity>[];

    for (final notification in notifications) {
      if (_isSameDay(notification.createdAt, today)) {
        todayList.add(notification);
      } else if (_isSameDay(notification.createdAt, yesterday)) {
        yesterdayList.add(notification);
      } else {
        olderList.add(notification);
      }
    }

    return {
      'today': todayList,
      'yesterday': yesterdayList,
      'older': olderList,
    };
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
