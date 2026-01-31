import 'dart:convert';
import 'dart:math';
import '../../../../database/database_helper.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/utils/device_helpers.dart';
import 'dart:developer' as developer;

/// Session management service
/// Handles login sessions, tokens, and session lifecycle
class SessionService {
  static const String _sessionTokenKey = 'session_token';

  /// Generate a secure random session token
  static String generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Create a new session for user
  static Future<String> createSession({
    required String userId,
    required String username,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final sessionToken = generateSessionToken();
      final deviceInfo = await DeviceHelpers.getDeviceInfo();
      final ipAddress = await DeviceHelpers.getIpAddress();

      await db.insert(
        'user_sessions',
        {
          'id': 'session_${DateTime.now().millisecondsSinceEpoch}_$userId',
          'user_id': userId,
          'session_token': sessionToken,
          'login_time': DateTime.now().toIso8601String(),
          'last_activity': DateTime.now().toIso8601String(),
          'device_info': deviceInfo,
          'ip_address': ipAddress,
          'is_active': 1,
        },
      );

      // Store in Hive for quick access
      await HiveStorage.setSecure(_sessionTokenKey, sessionToken);

      developer.log('✅ تم إنشاء جلسة جديدة: $username', name: 'SessionService');

      return sessionToken;
    } catch (e) {
      developer.log('❌ خطأ في إنشاء الجلسة: $e', name: 'SessionService');
      rethrow;
    }
  }

  /// Get active sessions for a user
  static Future<List<Map<String, dynamic>>> getActiveSessions(
      String userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final sessions = await db.query(
        'user_sessions',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'login_time DESC',
      );

      return sessions;
    } catch (e) {
      developer.log('❌ خطأ في جلب الجلسات النشطة: $e', name: 'SessionService');
      return [];
    }
  }

  /// Terminate a specific session
  static Future<bool> terminateSession(String sessionToken) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.update(
        'user_sessions',
        {'is_active': 0},
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

      developer.log('✅ تم إنهاء الجلسة', name: 'SessionService');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في إنهاء الجلسة: $e', name: 'SessionService');
      return false;
    }
  }

  /// Terminate all sessions for a user (logout from all devices)
  static Future<bool> terminateAllSessions(String userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.update(
        'user_sessions',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Clear Hive storage
      await HiveStorage.removeSecure(_sessionTokenKey);

      developer.log('✅ تم إنهاء جميع الجلسات للمستخدم: $userId',
          name: 'SessionService');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في إنهاء جميع الجلسات: $e', name: 'SessionService');
      return false;
    }
  }

  /// Get current session token
  static Future<String?> getCurrentSessionToken() async {
    return HiveStorage.getSecure<String>(_sessionTokenKey);
  }

  /// Check if session is valid
  static Future<bool> isSessionValid(String sessionToken) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final sessions = await db.query(
        'user_sessions',
        where: 'session_token = ? AND is_active = 1',
        whereArgs: [sessionToken],
      );

      return sessions.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
