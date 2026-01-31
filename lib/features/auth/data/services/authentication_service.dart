import '../../../../database/database_helper.dart';
import '../../../../core/services/password_hasher.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/services/audit_logger.dart';
import '../../domain/models/user.dart';
import './session_service.dart';
import 'dart:developer' as developer;

/// Authentication service
/// Handles user login, logout, and session management
class AuthenticationService {
  static const String _currentUserKey = 'current_user_id';

  /// Login user with username and password
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Find active user
      final users = await db.query(
        'users',
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'error': 'اسم المستخدم غير موجود أو غير مفعل',
        };
      }

      final user = User.fromMap(users.first);

      // Verify password (with legacy hash upgrade support)
      bool passwordValid = false;

      if (PasswordHasher.isLegacyHash(user.passwordHash)) {
        // Legacy hash - verify and upgrade
        final upgradedHash = PasswordHasher.upgradeLegacyHash(
          user.passwordHash,
          password,
        );

        if (upgradedHash != null) {
          passwordValid = true;

          // Upgrade hash immediately
          await db.update(
            'users',
            {
              'password_hash': upgradedHash,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [user.id],
          );

          developer.log('✅ تم ترقية hash كلمة المرور للمستخدم: $username',
              name: 'AuthenticationService');
        }
      } else {
        // New hash - normal verify
        passwordValid = PasswordHasher.verify(password, user.passwordHash);
      }

      if (!passwordValid) {
        return {
          'success': false,
          'error': 'كلمة المرور خاطئة',
        };
      }

      // Create new session
      final sessionToken = await SessionService.createSession(
        userId: user.id,
        username: username,
      );

      // Update last login
      await db.update(
        'users',
        {
          'last_login': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Save session to Hive (for quick access)
      await HiveStorage.setSecure(_currentUserKey, user.id);

      // Log activity
      await AuditLogger().logLogin(
        user.id,
        username,
      );

      developer.log('✅ تسجيل دخول ناجح: $username',
          name: 'AuthenticationService');

      return {
        'success': true,
        'user': user,
        'sessionToken': sessionToken,
      };
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الدخول: $e', name: 'AuthenticationService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Logout current user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final currentUserId = HiveStorage.getSecure<String>(_currentUserKey);

      if (currentUserId == null) {
        return {
          'success': false,
          'error': 'لا يوجد مستخدم مسجل دخول',
        };
      }

      // Terminate all sessions
      await SessionService.terminateAllSessions(currentUserId);

      // Clear Hive
      await HiveStorage.removeSecure(_currentUserKey);

      // Log activity
      await AuditLogger().logLogout(
        currentUserId,
        currentUserId, // We don't have username here
      );

      developer.log('✅ تسجيل خروج ناجح', name: 'AuthenticationService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الخروج: $e', name: 'AuthenticationService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get currently logged in user
  static Future<User?> getCurrentUser() async {
    try {
      final currentUserId = HiveStorage.getSecure<String>(_currentUserKey);

      if (currentUserId == null) {
        return null;
      }

      // Verify session is still valid
      final sessionToken = await SessionService.getCurrentSessionToken();
      if (sessionToken == null) {
        return null;
      }

      final isValid = await SessionService.isSessionValid(sessionToken);
      if (!isValid) {
        await HiveStorage.removeSecure(_currentUserKey);
        return null;
      }

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUserId],
      );

      if (users.isEmpty) {
        await HiveStorage.removeSecure(_currentUserKey);
        return null;
      }

      return User.fromMap(users.first);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم الحالي: $e',
          name: 'AuthenticationService');
      return null;
    }
  }

  /// Check if user has specific permission
  static bool hasPermission(User user, String permission) {
    return user.hasPermission(permission);
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
