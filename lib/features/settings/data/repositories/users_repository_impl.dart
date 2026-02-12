import 'package:drift/drift.dart';

import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/repositories/settings_repository.dart'; // For Either, Unit
import '../../domain/failures/settings_failure.dart';

/// Users Repository implementation with Either type using Drift
///
/// Never throws exceptions - always returns Either
class UsersRepositoryImpl implements UsersRepository {
  final UsersDriftDao _dao;

  UsersRepositoryImpl(this._dao);

  @override
  Future<Either<SettingsFailure, User>> createUser(
    User user, {
    String? createdBy,
  }) async {
    try {
      await _dao.createUser(UsersCompanion.insert(
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        email: Value(user.email),
        phone: Value(user.phone),
        passwordHash: user.passwordHash,
        role: Value(user.role.name),
        permissions: Value(user.permissions.join(',')),
        isActive: Value(user.isActive),
        forcePasswordChange: Value(user.forcePasswordChange),
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        createdBy: Value(createdBy),
      ));
      return Either.right(user);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في إنشاء المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> deleteUser(String userId) async {
    try {
      await _dao.deleteUser(userId);
      return const Either.right(Unit.unit);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في حذف المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, List<User>>> getActiveUsers() async {
    try {
      final entries = await _dao.getActiveUsers();
      final users = entries.map(_mapEntryToUser).toList();
      return Either.right(users);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدمين: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User?>> getUserById(String userId) async {
    try {
      final entry = await _dao.findById(userId);
      if (entry == null) return const Either.right(null);
      return Either.right(_mapEntryToUser(entry));
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User?>> getUserByUsername(
      String username) async {
    try {
      final entry = await _dao.findByUsername(username);
      if (entry == null) return const Either.right(null);
      return Either.right(_mapEntryToUser(entry));
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User>> updatePassword(
    String userId,
    String newPasswordHash, {
    bool forceChange = false,
  }) async {
    try {
      await _dao.updatePassword(userId, newPasswordHash,
          forceChange: forceChange);

      final userResult = await getUserById(userId);
      return userResult.fold(
        (failure) => Either.left(failure),
        (user) {
          if (user == null) {
            return const Either.left(UserNotFoundFailure());
          }
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في تحديث كلمة المرور: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User>> updatePermissions(
    String userId,
    List<String> permissions,
  ) async {
    try {
      await _dao.updatePermissions(userId, permissions);

      final userResult = await getUserById(userId);
      return userResult.fold(
        (failure) => Either.left(failure),
        (user) {
          if (user == null) {
            return const Either.left(UserNotFoundFailure());
          }
          return Either.right(user);
        },
      );
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في تحديث الصلاحيات: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User>> updateUser(User user) async {
    try {
      await _dao.updateUser(
        user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role.name,
        permissions: user.permissions,
        isActive: user.isActive,
      );
      return Either.right(user);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في تحديث المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, bool>> usernameExists(String username) async {
    try {
      final exists = await _dao.usernameExists(username);
      return Either.right(exists);
    } catch (e) {
      return Either.left(
          DatabaseSettingsFailure('فشل في التحقق من المستخدم: $e'));
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
