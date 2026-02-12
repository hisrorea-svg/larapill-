import 'dart:io';
import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app_database.dart';
import '../database_provider.dart';

/// Service for database management operations: backup, restore, integrity check, cleanup
/// This replaces DatabaseHelper usages in settings_screen.dart
class DatabaseManagementService {
  final AppDatabase _db;

  DatabaseManagementService(this._db);

  // ============ Backup Operations ============

  /// Create a backup of the current database
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'larapill_backup_$timestamp.db';
      final backupPath = '${backupDir.path}/$fileName';

      // Get the database file path
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      // Checkpoint to flush WAL to main database before backup
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

      await dbFile.copy(backupPath);

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('فشل في إنشاء ملف النسخة الاحتياطية');
      }

      final fileSize = await backupFile.length();

      developer.log(
          '✅ تم إنشاء نسخة احتياطية: $fileName (${(fileSize / 1024).toStringAsFixed(1)} KB)',
          name: 'Backup');

      return {
        'success': true,
        'path': backupPath,
        'fileName': fileName,
        'size': fileSize,
        'date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ خطأ في إنشاء نسخة احتياطية: $e', name: 'Backup');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get list of available backups
  Future<List<Map<String, dynamic>>> getBackupsList() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final backups = <Map<String, dynamic>>[];
      final files = backupDir.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.db')) {
          final stat = await file.stat();
          final fileName = p.basename(file.path);
          backups.add({
            'name': fileName,
            'path': file.path,
            'date': stat.modified.toIso8601String(),
            'size': stat.size,
          });
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b['date'].compareTo(a['date']));
      return backups;
    } catch (e) {
      developer.log('❌ خطأ في قراءة النسخ الاحتياطية: $e', name: 'Backup');
      return [];
    }
  }

  /// Restore database from backup
  /// Warning: This will close the database and replace it
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('ملف النسخة الاحتياطية غير موجود');
      }

      final dbPath = await _getDatabasePath();

      // Close the current database connection
      await _db.close();

      // Replace the database file
      await backupFile.copy(dbPath);

      developer.log('✅ تم استعادة النسخة الاحتياطية بنجاح', name: 'Backup');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في استعادة النسخة الاحتياطية: $e', name: 'Backup');
      return false;
    }
  }

  // ============ Database Integrity ============

  /// Check database integrity
  Future<Map<String, dynamic>> checkIntegrity() async {
    try {
      final result = await _db
          .customSelect(
            'PRAGMA integrity_check',
          )
          .get();

      final isOk = result.isNotEmpty &&
          result.first.read<String?>('integrity_check') == 'ok';

      return {
        'isOk': isOk,
        'details': result.map((r) => r.data).toList(),
      };
    } catch (e) {
      developer.log('❌ خطأ في فحص سلامة قاعدة البيانات: $e', name: 'Database');
      return {
        'isOk': false,
        'error': e.toString(),
      };
    }
  }

  /// Get table statistics
  Future<Map<String, int>> getTableStats() async {
    try {
      final tables = await _db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();

      final stats = <String, int>{};
      for (var table in tables) {
        final tableName = table.read<String>('name');
        final countResult = await _db
            .customSelect(
              'SELECT COUNT(*) as count FROM $tableName',
            )
            .getSingle();
        stats[tableName] = countResult.read<int>('count');
      }
      return stats;
    } catch (e) {
      developer.log('❌ خطأ في حساب إحصائيات الجداول: $e', name: 'Database');
      return {};
    }
  }

  // ============ Cleanup Operations ============

  /// Clean old data from the database
  Future<int> cleanOldData() async {
    int totalDeleted = 0;

    try {
      // Delete old sales (older than 1 year)
      final oldSalesDate =
          DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
      totalDeleted += await _db.customUpdate(
        'DELETE FROM sales WHERE created_at < ?',
        variables: [Variable(oldSalesDate)],
        updateKind: UpdateKind.delete,
      );

      // Delete old system logs (older than 6 months)
      final oldLogsDate =
          DateTime.now().subtract(const Duration(days: 180)).toIso8601String();

      // Check if system_logs table exists
      try {
        totalDeleted += await _db.customUpdate(
          'DELETE FROM system_logs WHERE created_at < ?',
          variables: [Variable(oldLogsDate)],
          updateKind: UpdateKind.delete,
        );
      } catch (_) {
        // Table might not exist
      }

      // Vacuum to reclaim space
      await _db.customStatement('VACUUM');

      developer.log('✅ تم حذف $totalDeleted سجل قديم', name: 'Database');
      return totalDeleted;
    } catch (e) {
      developer.log('❌ خطأ في تنظيف البيانات: $e', name: 'Database');
      return totalDeleted;
    }
  }

  /// Vacuum the database to reclaim space
  Future<void> vacuum() async {
    await _db.customStatement('VACUUM');
  }

  /// Reset database - delete all data except users
  Future<void> resetDatabase() async {
    try {
      final tables = await _db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();

      for (var table in tables) {
        final tableName = table.read<String>('name');
        // Skip users table and drift internal tables
        if (tableName != 'users' && !tableName.startsWith('_')) {
          await _db.customStatement('DELETE FROM $tableName');
        }
      }

      // Re-insert default pharmacy settings
      await _db.customStatement('''
        INSERT OR IGNORE INTO pharmacy_settings (name_ar, name_en, created_at, updated_at)
        VALUES ('صيدلية LaRaPill', 'LaRaPill Pharmacy', datetime('now'), datetime('now'))
      ''');

      await _db.customStatement('VACUUM');
      developer.log('✅ تم إعادة تعيين قاعدة البيانات', name: 'Database');
    } catch (e) {
      developer.log('❌ خطأ في إعادة تعيين قاعدة البيانات: $e',
          name: 'Database');
      rethrow;
    }
  }

  /// Reset database with audit logging
  Future<void> resetDatabaseWithAudit({
    required String userId,
    required String userName,
    String? backupFileName,
  }) async {
    await resetDatabase();

    // Log audit after reset
    try {
      await _db.auditLogDriftDao.logDatabaseReset(
        userId: userId,
        userName: userName,
        operationType: 'reset_database',
        backupFileName: backupFileName,
      );
    } catch (e) {
      developer.log('⚠️ Audit logging failed: $e',
          name: 'DatabaseManagementService');
    }
  }

  // ============ Helper Methods ============

  /// Get the database file path
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'larapill.db');
  }
}

// ============ Riverpod Provider ============

/// Provider for DatabaseManagementService
final databaseManagementServiceProvider =
    Provider<DatabaseManagementService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DatabaseManagementService(db);
});
