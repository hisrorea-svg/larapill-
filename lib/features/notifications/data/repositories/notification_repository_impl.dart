import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/notification_drift_dao.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/entities/notification_priority.dart';
import '../../domain/repositories/notification_repository.dart';

/// تطبيق مستودع الإشعارات - Data Layer (Using Drift DAO)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDriftDao _notificationDao;

  const NotificationRepositoryImpl(this._notificationDao);

  @override
  Stream<List<NotificationEntity>> watchAll() {
    return _notificationDao
        .watchAll()
        .map((entries) => entries.map(_mapEntryToEntity).toList());
  }

  @override
  Future<List<NotificationEntity>> getAll() async {
    final entries = await _notificationDao.findAll();
    return entries.map(_mapEntryToEntity).toList();
  }

  @override
  Future<void> add(NotificationEntity notification) async {
    // Serialize actionData to JSON string
    String? actionDataJson;
    if (notification.actionData != null) {
      actionDataJson = jsonEncode(notification.actionData);
    }

    final companion = NotificationsCompanion.insert(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      type: notification.type.name,
      priority: notification.priority.name,
      isRead: Value(notification.isRead),
      createdAt: notification.createdAt,
      actionData: Value(actionDataJson),
      userId: Value(notification.userId),
    );
    await _notificationDao.insertNotification(companion);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _notificationDao.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await _notificationDao.markAllAsRead();
  }

  @override
  Future<void> delete(String id) async {
    await _notificationDao.deleteNotification(id);
  }

  @override
  Future<void> clearRead() async {
    await _notificationDao.clearRead();
  }

  @override
  Future<int> getUnreadCount() async {
    return await _notificationDao.getUnreadCount();
  }

  /// Map NotificationEntry to NotificationEntity
  NotificationEntity _mapEntryToEntity(NotificationEntry entry) {
    // Deserialize JSON string to Map
    Map<String, dynamic>? actionData;
    if (entry.actionData != null && entry.actionData!.isNotEmpty) {
      try {
        actionData = jsonDecode(entry.actionData!) as Map<String, dynamic>;
      } catch (e) {
        actionData = null;
      }
    }

    return NotificationEntity(
      id: entry.id,
      title: entry.title,
      body: entry.body,
      type: NotificationType.values.firstWhere(
        (t) => t.name == entry.type,
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == entry.priority,
        orElse: () => NotificationPriority.medium,
      ),
      isRead: entry.isRead,
      createdAt: entry.createdAt,
      actionData: actionData,
      userId: entry.userId,
    );
  }
}

/// Riverpod provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dao = ref.watch(notificationDriftDaoProvider);
  return NotificationRepositoryImpl(dao);
});
