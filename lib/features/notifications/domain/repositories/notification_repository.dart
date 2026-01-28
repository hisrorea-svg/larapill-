import '../entities/notification_entity.dart';

/// واجهة مستودع الإشعارات - Domain Layer
/// تحدد العقد الذي يجب أن تلتزم به طبقة البيانات
abstract class NotificationRepository {
  /// مراقبة جميع الإشعارات لحظياً
  Stream<List<NotificationEntity>> watchAll();

  /// الحصول على جميع الإشعارات
  Future<List<NotificationEntity>> getAll();

  /// إضافة إشعار جديد
  Future<void> add(NotificationEntity notification);

  /// تعليم إشعار كمقروء
  Future<void> markAsRead(String id);

  /// تعليم جميع الإشعارات كمقروءة
  Future<void> markAllAsRead();

  /// حذف إشعار
  Future<void> delete(String id);

  /// حذف الإشعارات المقروءة
  Future<void> clearRead();

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount();
}
