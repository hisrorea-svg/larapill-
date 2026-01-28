import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/clear_read_notifications_usecase.dart';
import 'notification_state.dart';

/// Controller الإشعارات - Presentation Layer
class NotificationController extends StateNotifier<NotificationState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationAsReadUseCase _markAsRead;
  final MarkAllNotificationsAsReadUseCase _markAllAsRead;
  final ClearReadNotificationsUseCase _clearRead;

  NotificationController({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationAsReadUseCase markAsRead,
    required MarkAllNotificationsAsReadUseCase markAllAsRead,
    required ClearReadNotificationsUseCase clearRead,
  })  : _getNotifications = getNotifications,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead,
        _clearRead = clearRead,
        super(NotificationState.initial()) {
    // تحميل الإشعارات عند الإنشاء
    loadNotifications();
  }

  /// تحميل الإشعارات
  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final notifications = await _getNotifications();
      state = NotificationState.success(notifications);
    } catch (e) {
      state = NotificationState.error(e.toString());
    }
  }

  /// تعليم إشعار كمقروء
  Future<void> markAsRead(String id) async {
    try {
      await _markAsRead(id);
      // التحديث سيحدث تلقائياً عبر Stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// تعليم جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      await _markAllAsRead();
      // التحديث سيحدث تلقائياً عبر Stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// حذف الإشعارات المقروءة
  Future<void> clearReadNotifications() async {
    try {
      await _clearRead();
      // التحديث سيحدث تلقائياً عبر Stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// تحديث الحالة مع إشعارات جديدة (يُستدعى من Stream)
  void updateNotifications(List<NotificationEntity> notifications) {
    state = NotificationState.success(notifications);
  }
}
