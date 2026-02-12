import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

/// خدمة إعادة ضبط ومسح جميع بيانات التطبيق
class AppResetService {
  /// مسح قاعدة البيانات + الكاش + الإعدادات المحلية
  /// [confirmed] يجب أن تكون true لتأكيد الحذف
  static Future<void> clearAllData({bool confirmed = false}) async {
    if (!confirmed) {
      developer.log('⚠️ تم إلغاء مسح البيانات لعدم التأكيد',
          name: 'AppResetService');
      return;
    }
    developer.log('🗑️ بدء مسح جميع بيانات التطبيق...',
        name: 'AppResetService');

    // 1. مسح SharedPreferences
    await _clearSharedPreferences();

    // 2. مسح ملفات الكاش
    await _clearCache();

    // 3. مسح قاعدة البيانات
    await _clearDatabase();

    // 4. مسح الملفات المؤقتة
    await _clearTempFiles();

    developer.log('✅ تم مسح جميع البيانات بنجاح', name: 'AppResetService');
  }

  /// مسح SharedPreferences (الإعدادات المحفوظة)
  static Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('✅ SharedPreferences تم مسحها', name: 'AppResetService');
    } catch (e) {
      developer.log('❌ خطأ في مسح SharedPreferences: $e',
          name: 'AppResetService');
    }
  }

  /// مسح ملفات الكاش
  static Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await _deleteDirectory(cacheDir);
      }
      developer.log('✅ الكاش تم مسحه', name: 'AppResetService');
    } catch (e) {
      developer.log('❌ خطأ في مسح الكاش: $e', name: 'AppResetService');
    }
  }

  /// مسح قاعدة البيانات (جميع إصداراتها)
  static Future<void> _clearDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();

      // قائمة بجميع قواعد البيانات المحتملة
      final databases = [
        'larapill.db',
        'larapill_drift.db',
        'larapill_v2.db',
        'larapill_v3.db', // الحالية
        'larapill_pharmacy.db',
        'app_database.db',
      ];

      for (final dbName in databases) {
        final dbFile = File(p.join(dbFolder.path, dbName));
        if (await dbFile.exists()) {
          await dbFile.delete();
          developer.log('🗑️ تم حذف قاعدة البيانات: $dbName',
              name: 'AppResetService');
        }

        // حذف ملفات الـ WAL والـ SHM إن وجدت
        final walFile = File('${dbFile.path}-wal');
        final shmFile = File('${dbFile.path}-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();
      }

      developer.log('✅ قواعد البيانات تم مسحها', name: 'AppResetService');
    } catch (e) {
      developer.log('❌ خطأ في مسح قاعدة البيانات: $e', name: 'AppResetService');
    }
  }

  /// مسح الملفات المؤقتة
  static Future<void> _clearTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final larapillTemps = tempDir
          .listSync()
          .where((f) => f.path.toLowerCase().contains('larapill'));

      for (final file in larapillTemps) {
        await file.delete(recursive: true);
      }
      developer.log('✅ الملفات المؤقتة تم مسحها', name: 'AppResetService');
    } catch (e) {
      developer.log('❌ خطأ في مسح الملفات المؤقتة: $e',
          name: 'AppResetService');
    }
  }

  /// حذف مجلد بشكل متكرر
  static Future<void> _deleteDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(); // إعادة إنشاء المجلد الفارغ
    }
  }

  /// إعادة ضبط فقط الإعدادات (بدون بيانات المخزون)
  static Future<void> resetSettingsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // احتفظ ببعض المفاتيح المهمة واحذف الباقي
      final keysToKeep = ['first_run', 'installation_date'];
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }

      developer.log('✅ الإعدادات تم إعادة ضبطها', name: 'AppResetService');
    } catch (e) {
      developer.log('❌ خطأ في إعادة ضبط الإعدادات: $e',
          name: 'AppResetService');
    }
  }
}
