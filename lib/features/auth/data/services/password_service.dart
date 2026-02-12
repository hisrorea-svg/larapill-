import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/password_hasher.dart';
import '../../../../core/services/audit_logger.dart';
import '../../domain/entities/user.dart';
import 'dart:developer' as developer;

/// Password management service
/// Handles password hashing, changes, and resets
class PasswordService {
  static PasswordService? _instance;
  final UsersDriftDao _dao;

  PasswordService(this._dao);

  /// Initialize with DAO from DI
  static void init(UsersDriftDao dao) {
    _instance = PasswordService(dao);
  }

  /// Hash a password using Argon2
  static String hashPassword(String password) {
    return PasswordHasher.hash(password);
  }

  /// Static changePassword wrapper for backward compatibility
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_instance == null) {
      return {'success': false, 'error': 'Service not initialized'};
    }
    return _instance!._changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// Change user password (requires old password verification)
  Future<Map<String, dynamic>> _changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Get user
      final userEntry = await _dao.findById(userId);

      if (userEntry == null) {
        return {
          'success': false,
          'error': 'المستخدم غير موجود',
        };
      }

      final user = _mapEntryToUser(userEntry);

      // Verify old password
      bool oldPasswordValid = false;

      if (PasswordHasher.isLegacyHash(user.passwordHash)) {
        final upgradedHash = PasswordHasher.upgradeLegacyHash(
          user.passwordHash,
          oldPassword,
        );
        oldPasswordValid = upgradedHash != null;
      } else {
        oldPasswordValid =
            PasswordHasher.verify(oldPassword, user.passwordHash);
      }

      if (!oldPasswordValid) {
        return {
          'success': false,
          'error': 'كلمة المرور القديمة غير صحيحة',
        };
      }

      // Update password and remove force_password_change flag
      final newHash = hashPassword(newPassword);
      await _dao.updatePassword(userId, newHash, forceChange: false);

      // Log activity
      await AuditLogger().log(
        action: AuditActionType.passwordChange,
        userId: userId,
        description: 'تغيير كلمة المرور',
      );

      developer.log('✅ تم تغيير كلمة المرور للمستخدم: $userId',
          name: 'PasswordService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في تغيير كلمة المرور: $e', name: 'PasswordService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Reset user password (admin action, no old password required)
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String newPassword,
    required String adminId,
  }) async {
    try {
      final newHash = hashPassword(newPassword);
      await _dao.updatePassword(userId, newHash);

      // Log activity
      await AuditLogger().log(
        action: AuditActionType.passwordReset,
        userId: adminId,
        description: 'إعادة تعيين كلمة مرور المستخدم: $userId',
      );

      developer.log('✅ تم إعادة تعيين كلمة المرور للمستخدم: $userId',
          name: 'PasswordService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في إعادة تعيين كلمة المرور: $e',
          name: 'PasswordService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Force reset user password (simplified version)
  Future<Map<String, dynamic>> resetUserPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final newHash = hashPassword(newPassword);
      await _dao.updatePassword(userId, newHash);

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
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
