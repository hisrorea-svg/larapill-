import '../../../../database/database_helper.dart';
import '../../../../core/services/password_hasher.dart';
import '../../../../core/services/audit_logger.dart';
import '../../domain/models/user.dart';
import 'dart:developer' as developer;

/// Password management service
/// Handles password hashing, changes, and resets
class PasswordService {
  /// Hash a password using Argon2
  static String hashPassword(String password) {
    return PasswordHasher.hash(password);
  }

  /// Change user password (requires old password verification)
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get user
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'error': 'المستخدم غير موجود',
        };
      }

      final user = User.fromMap(users.first);

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

      await db.update(
        'users',
        {
          'password_hash': newHash,
          'force_password_change': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

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
  static Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String newPassword,
    required String adminId,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final newHash = hashPassword(newPassword);

      await db.update(
        'users',
        {
          'password_hash': newHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

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
  static Future<Map<String, dynamic>> resetUserPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final newHash = hashPassword(newPassword);

      await db.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
