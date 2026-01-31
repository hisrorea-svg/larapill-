import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../database/database_helper.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/notification_model.dart';

/// Migration من SharedPreferences إلى SQLite
class NotificationMigration {
  static const String _oldKey = 'app_notifications';
  static const String _migrationKey = 'notifications_migrated_to_sqlite';

  /// تنفيذ Migration
  static Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();

    // تحقق إذا تم Migration بالفعل
    final alreadyMigrated = prefs.getBool(_migrationKey) ?? false;
    if (alreadyMigrated) {
      return;
    }

    try {
      // الحصول على البيانات القديمة
      final oldData = prefs.getStringList(_oldKey);
      if (oldData == null || oldData.isEmpty) {
        // لا توجد بيانات للترحيل
        await prefs.setBool(_migrationKey, true);
        return;
      }

      // إنشاء datasource
      final datasource = NotificationLocalDataSource(DatabaseHelper());

      int successCount = 0;
      int failCount = 0;

      // ترحيل كل إشعار
      for (final jsonStr in oldData) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final model = NotificationModel.fromMapSafe(map);

          if (model != null && model.id.isNotEmpty) {
            await datasource.insert(model);
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          // تجاهل الأخطاء واستمر
        }
      }

      // حذف البيانات القديمة بعد Migration الناجح
      if (successCount > 0) {
        await prefs.remove(_oldKey);
      }

      // تعليم Migration كمكتمل
      await prefs.setBool(_migrationKey, true);

      debugPrint(
          '✅ Notification Migration Complete: $successCount migrated, $failCount failed');
    } catch (e) {
      debugPrint('❌ Notification Migration Error: $e');
      // لا نعلم Migration كمكتمل في حالة الخطأ
    }
  }

  /// إعادة تعيين Migration (للاختبار فقط)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
  }
}
