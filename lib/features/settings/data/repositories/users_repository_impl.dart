import '../../../../database/database_helper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/repositories/settings_repository.dart'; // For Either, Unit
import '../../domain/failures/settings_failure.dart';
import '../../../../services/user_service.dart' as service;
import '../mappers/user_mapper.dart';

/// Users Repository implementation with Either type
///
/// Never throws exceptions - always returns Either
class UsersRepositoryImpl implements UsersRepository {
  final dbHelper = DatabaseHelper();

  @override
  Future<Either<SettingsFailure, UserEntity>> createUser(
    UserEntity user, {
    String? createdBy,
  }) async {
    try {
      final db = await dbHelper.database;
      final map = {
        'id': user.id,
        'username': user.username,
        'full_name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'password_hash': user.passwordHash,
        'role': user.role.name,
        'permissions': user.permissions.join(','),
        'is_active': user.isActive ? 1 : 0,
        'force_password_change': user.forcePasswordChange ? 1 : 0,
        'last_login': user.lastLogin?.toIso8601String(),
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': user.updatedAt.toIso8601String(),
        'created_by': user.createdBy,
      };
      await db.insert('users', map);
      return Either.right(user);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في إنشاء المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> deleteUser(String userId) async {
    try {
      final db = await dbHelper.database;
      await db.update('users', {'is_active': 0},
          where: 'id = ?', whereArgs: [userId]);
      return const Either.right(Unit.unit);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في حذف المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, List<UserEntity>>> getActiveUsers() async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query('users', where: 'is_active = 1');
      final users = maps
          .map((map) => UserMapper.toEntity(service.User.fromMap(map)))
          .toList();
      return Either.right(users);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدمين: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, UserEntity?>> getUserById(
      String userId) async {
    try {
      final db = await dbHelper.database;
      final maps =
          await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (maps.isEmpty) return const Either.right(null);
      return Either.right(
          UserMapper.toEntity(service.User.fromMap(maps.first)));
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, UserEntity?>> getUserByUsername(
      String username) async {
    try {
      final db = await dbHelper.database;
      final maps =
          await db.query('users', where: 'username = ?', whereArgs: [username]);
      if (maps.isEmpty) return const Either.right(null);
      return Either.right(
          UserMapper.toEntity(service.User.fromMap(maps.first)));
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, UserEntity>> updatePassword(
    String userId,
    String newPasswordHash, {
    bool forceChange = false,
  }) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'force_password_change': forceChange ? 1 : 0
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

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
  Future<Either<SettingsFailure, UserEntity>> updatePermissions(
    String userId,
    List<String> permissions,
  ) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'users',
        {'permissions': permissions.join(',')},
        where: 'id = ?',
        whereArgs: [userId],
      );

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
  Future<Either<SettingsFailure, UserEntity>> updateUser(
      UserEntity user) async {
    try {
      final db = await dbHelper.database;
      final map = {
        'username': user.username,
        'full_name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.name,
        'permissions': user.permissions.join(','),
        'is_active': user.isActive ? 1 : 0,
      };
      await db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
      return Either.right(user);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في تحديث المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, bool>> usernameExists(String username) async {
    final userResult = await getUserByUsername(username);
    return userResult.fold(
      (failure) => Either.left(failure),
      (user) => Either.right(user != null),
    );
  }
}
