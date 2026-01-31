import '../../../../database/database_helper.dart';
import '../../domain/models/user.dart';
import 'dart:developer' as developer;

/// Permission management service
/// Handles authorization checks and default permissions
class PermissionService {
  /// Check if user has specific permission
  static Future<bool> checkPermission(String userId, String permission) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) return false;

      final user = User.fromMap(result.first);
      return user.hasPermission(permission);
    } catch (e) {
      developer.log('❌ خطأ في التحقق من الصلاحية: $e',
          name: 'PermissionService');
      return false;
    }
  }

  /// Get default permissions for a role
  static List<String> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return ['all'];
      case UserRole.manager:
        return ['sales', 'inventory', 'reports', 'suppliers', 'users'];
      case UserRole.pharmacist:
        return ['sales', 'inventory', 'reports'];
      case UserRole.cashier:
        return ['sales'];
    }
  }

  /// Update user permissions
  static Future<Map<String, dynamic>> updatePermissions({
    required String userId,
    required List<String> permissions,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.update(
        'users',
        {
          'permissions': permissions.join(','),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return {
        'success': true,
        'message': 'تم تحديث الصلاحيات بنجاح',
      };
    } catch (e) {
      developer.log('❌ خطأ في تحديث الصلاحيات: $e', name: 'PermissionService');
      return {
        'success': false,
        'error': 'فشل تحديث الصلاحيات',
      };
    }
  }
}
