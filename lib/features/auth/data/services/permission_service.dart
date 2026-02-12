import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../domain/entities/user.dart';
import 'dart:developer' as developer;

/// Permission management service
/// Handles authorization checks and default permissions
class PermissionService {
  final UsersDriftDao _dao;

  PermissionService(this._dao);

  /// Check if user has specific permission
  Future<bool> checkPermission(String userId, String permission) async {
    try {
      final userEntry = await _dao.findById(userId);

      if (userEntry == null) return false;

      final user = _mapEntryToUser(userEntry);
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
  Future<Map<String, dynamic>> updatePermissions({
    required String userId,
    required List<String> permissions,
  }) async {
    try {
      await _dao.updatePermissions(userId, permissions);

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
