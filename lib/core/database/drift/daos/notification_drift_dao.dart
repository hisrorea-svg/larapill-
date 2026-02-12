import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_database.dart';
import '../database_provider.dart';

part 'notification_drift_dao.g.dart';

/// Drift DAO for notifications operations
@DriftAccessor(tables: [Notifications])
class NotificationDriftDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDriftDaoMixin {
  NotificationDriftDao(super.db);

  /// Get all notifications ordered by creation date
  Future<List<NotificationEntry>> findAll() {
    return (select(notifications)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Watch all notifications (real-time stream)
  Stream<List<NotificationEntry>> watchAll() {
    return (select(notifications)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get a notification by ID
  Future<NotificationEntry?> findById(String id) {
    return (select(notifications)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new notification
  Future<void> insertNotification(NotificationsCompanion notification) async {
    await into(notifications).insertOnConflictUpdate(notification);
    // Limit notifications count to 100
    await _limitNotifications();
  }

  /// Update a notification
  Future<bool> updateNotification(NotificationEntry notification) async {
    return await update(notifications).replace(notification);
  }

  /// Delete a notification by ID
  Future<int> deleteNotification(String id) {
    return (delete(notifications)..where((n) => n.id.equals(id))).go();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    await (update(notifications)..where((n) => n.id.equals(id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await update(notifications)
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// Delete all read notifications
  Future<int> clearRead() {
    return (delete(notifications)..where((n) => n.isRead.equals(true))).go();
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    final query = selectOnly(notifications)
      ..addColumns([notifications.id.count()])
      ..where(notifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(notifications.id.count()) ?? 0;
  }

  /// Watch unread notifications count (real-time)
  Stream<int> watchUnreadCount() {
    final query = selectOnly(notifications)
      ..addColumns([notifications.id.count()])
      ..where(notifications.isRead.equals(false));
    return query
        .watchSingle()
        .map((row) => row.read(notifications.id.count()) ?? 0);
  }

  /// Get notifications by type
  Future<List<NotificationEntry>> findByType(String type) {
    return (select(notifications)
          ..where((n) => n.type.equals(type))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Get unread notifications
  Future<List<NotificationEntry>> findUnread() {
    return (select(notifications)
          ..where((n) => n.isRead.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Get notifications by user ID
  Future<List<NotificationEntry>> findByUserId(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Delete notifications older than a certain date
  Future<int> deleteOlderThan(DateTime date) {
    return (delete(notifications)
          ..where((n) => n.createdAt.isSmallerThanValue(date)))
        .go();
  }

  /// Limit notifications to keep only the latest 100
  Future<void> _limitNotifications() async {
    final count = await (selectOnly(notifications)
          ..addColumns([notifications.id.count()]))
        .getSingle()
        .then((row) => row.read(notifications.id.count()) ?? 0);

    if (count > 100) {
      // Delete oldest notifications beyond the limit
      final toDelete = count - 100;
      final oldestEntries = await (select(notifications)
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)
            ])
            ..limit(toDelete))
          .get();

      for (final entry in oldestEntries) {
        await (delete(notifications)..where((n) => n.id.equals(entry.id))).go();
      }
    }
  }
}

/// Provider for NotificationDriftDao
final notificationDriftDaoProvider = Provider<NotificationDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NotificationDriftDao(db);
});
