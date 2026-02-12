import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/services/password_hasher.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/services/audit_logger.dart';
import '../../domain/entities/user.dart';
import './session_service.dart';
import 'dart:developer' as developer;

/// Authentication service
/// Handles user login, logout, and session management
class AuthenticationService {
  static const String _currentUserKey = 'current_user_id';

  static AuthenticationService? _instance;
  final UsersDriftDao _dao;

  AuthenticationService(this._dao);

  /// Initialize with DAO from DI
  static void init(UsersDriftDao dao) {
    _instance = AuthenticationService(dao);
  }

  // ---- Static wrapper methods for backward compatibility ----

  /// Static login wrapper
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    if (_instance == null) {
      return {'success': false, 'error': 'Service not initialized'};
    }
    return _instance!._login(username, password);
  }

  /// Static logout wrapper
  static Future<Map<String, dynamic>> logout() async {
    if (_instance == null) {
      return {'success': false, 'error': 'Service not initialized'};
    }
    return _instance!._logout();
  }

  /// Static getCurrentUser wrapper
  static Future<User?> getCurrentUser() async {
    if (_instance == null) return null;
    return _instance!._getCurrentUser();
  }

  /// Static isAuthenticated wrapper
  static Future<bool> isAuthenticated() async {
    if (_instance == null) return false;
    return _instance!._isAuthenticated();
  }

  // ---- Instance methods (renamed with underscore prefix) ----

  /// Login user with username and password
  Future<Map<String, dynamic>> _login(String username, String password) async {
    try {
      // Find active user
      final userEntry = await _dao.findByUsername(username);

      if (userEntry == null || !userEntry.isActive) {
        return {
          'success': false,
          'error': 'اسم المستخدم غير موجود أو غير مفعل',
        };
      }

      final user = _mapEntryToUser(userEntry);

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
          await _dao.updatePassword(user.id, upgradedHash);

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
      await _dao.updateLastLogin(user.id);

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
  Future<Map<String, dynamic>> _logout() async {
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
  Future<User?> _getCurrentUser() async {
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

      final userEntry = await _dao.findById(currentUserId);

      if (userEntry == null) {
        await HiveStorage.removeSecure(_currentUserKey);
        return null;
      }

      return _mapEntryToUser(userEntry);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم الحالي: $e',
          name: 'AuthenticationService');
      return null;
    }
  }

  /// Check if user has specific permission
  bool hasPermission(User user, String permission) {
    return user.hasPermission(permission);
  }

  /// Check if user is authenticated
  Future<bool> _isAuthenticated() async {
    final user = await _getCurrentUser();
    return user != null;
  }

  /// Map Drift UserEntry to domain User
  User _mapEntryToUser(UserEntry entry) {
    return User(
      id: entry.id,
      username: entry.username,
      fullName: entry.fullName,
      email: entry.email,
      phone: entry.phone,
      passwordHash: entry.passwordHash,
      role: UserRole.fromString(entry.role),
      permissions: entry.permissions?.split(',') ?? [],
      isActive: entry.isActive,
      forcePasswordChange: entry.forcePasswordChange,
      lastLogin: entry.lastLogin,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      createdBy: entry.createdBy,
    );
  }
}
