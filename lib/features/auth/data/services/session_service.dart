import 'dart:convert';
import 'dart:math';
import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/utils/device_helpers.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as developer;

/// Session management service
/// Handles login sessions, tokens, and session lifecycle
class SessionService {
  static const String _sessionTokenKey = 'session_token';

  // Static DAO reference for static methods (will need to be set by DI)
  static UsersDriftDao? _dao;

  /// Initialize with DAO from DI
  static void init(UsersDriftDao dao) {
    _dao = dao;
  }

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
    if (_dao == null) {
      throw Exception('SessionService not initialized. Call init() first.');
    }

    try {
      final sessionToken = generateSessionToken();
      final deviceInfo = await DeviceHelpers.getDeviceInfo();
      final ipAddress = await DeviceHelpers.getIpAddress();
      final now = DateTime.now();

      await _dao!.createSession(UserSessionsCompanion.insert(
        id: 'session_${now.millisecondsSinceEpoch}_$userId',
        userId: userId,
        sessionToken: sessionToken,
        loginTime: now,
        lastActivity: now,
        deviceInfo: Value(deviceInfo),
        ipAddress: Value(ipAddress),
        isActive: const Value(true),
      ));

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
  static Future<List<UserSessionEntry>> getActiveSessions(String userId) async {
    if (_dao == null) return [];

    try {
      return await _dao!.getUserSessions(userId);
    } catch (e) {
      developer.log('❌ خطأ في جلب الجلسات النشطة: $e', name: 'SessionService');
      return [];
    }
  }

  /// Terminate a specific session
  static Future<bool> terminateSession(String sessionToken) async {
    if (_dao == null) return false;

    try {
      // Find session by token first
      await _dao!.invalidateSession(sessionToken);

      developer.log('✅ تم إنهاء الجلسة', name: 'SessionService');
      return true;
    } catch (e) {
      developer.log('❌ خطأ في إنهاء الجلسة: $e', name: 'SessionService');
      return false;
    }
  }

  /// Terminate all sessions for a user (logout from all devices)
  static Future<bool> terminateAllSessions(String userId) async {
    if (_dao == null) return false;

    try {
      await _dao!.invalidateAllUserSessions(userId);

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
    if (_dao == null) return false;

    try {
      final session = await _dao!.getSession(sessionToken);
      return session != null && session.isActive;
    } catch (e) {
      return false;
    }
  }
}
