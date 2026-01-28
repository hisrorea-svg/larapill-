import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../database/database_helper.dart';
import '../models/notification_model.dart';

/// مصدر البيانات المحلي للإشعارات - SQLite
class NotificationLocalDataSource {
  final DatabaseHelper _dbHelper;

  // Stream controller للتحديثات اللحظية
  final _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  NotificationLocalDataSource(this._dbHelper);

  /// جدول الإشعارات
  static const String tableName = 'notifications';

  /// إنشاء جدول الإشعارات
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        action_data TEXT,
        user_id TEXT
      )
    ''');

    // إنشاء فهرس للإشعارات غير المقروءة
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_is_read 
      ON $tableName(is_read)
    ''');

    // إنشاء فهرس للتاريخ
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at 
      ON $tableName(created_at DESC)
    ''');
  }

  /// Stream للمراقبة اللحظية
  Stream<List<NotificationModel>> watchAll() async* {
    // إرسال البيانات الحالية
    yield await getAll();

    // الاستماع للتحديثات
    await for (final notifications in _notificationsController.stream) {
      yield notifications;
    }
  }

  /// الحصول على جميع الإشعارات
  Future<List<NotificationModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// الحصول على إشعار بواسطة ID
  Future<NotificationModel?> getById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return NotificationModel.fromMap(maps.first);
    } catch (e) {
      return null;
    }
  }

  /// إضافة إشعار
  Future<void> insert(NotificationModel notification) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        tableName,
        notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // الحد الأقصى 100 إشعار
      await _limitNotifications(db);

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث إشعار
  Future<void> update(NotificationModel notification) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        tableName,
        notification.toMap(),
        where: 'id = ?',
        whereArgs: [notification.id],
      );

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// حذف إشعار
  Future<void> delete(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// تعليم كمقروء
  Future<void> markAsRead(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        tableName,
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// تعليم الكل كمقروء
  Future<void> markAllAsRead() async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        tableName,
        {'is_read': 1},
      );

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// حذف الإشعارات المقروءة
  Future<void> clearRead() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        tableName,
        where: 'is_read = ?',
        whereArgs: [1],
      );

      // بث التحديث
      await _broadcastUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE is_read = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// الحد من عدد الإشعارات (احتفظ بآخر 100)
  Future<void> _limitNotifications(Database db) async {
    try {
      // عد الإشعارات
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      if (count > 100) {
        // احذف الإشعارات القديمة
        await db.rawDelete('''
          DELETE FROM $tableName 
          WHERE id IN (
            SELECT id FROM $tableName 
            ORDER BY created_at ASC 
            LIMIT ${count - 100}
          )
        ''');
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  /// بث التحديثات
  Future<void> _broadcastUpdate() async {
    if (!_notificationsController.isClosed) {
      final notifications = await getAll();
      _notificationsController.add(notifications);
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _notificationsController.close();
  }
}
