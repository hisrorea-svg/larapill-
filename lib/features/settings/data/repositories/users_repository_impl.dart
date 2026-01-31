import '../../../../database/database_helper.dart';
import '../../../auth/domain/models/user.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/repositories/settings_repository.dart'; // For Either, Unit
import '../../domain/failures/settings_failure.dart';

/// Users Repository implementation with Either type
///
/// Never throws exceptions - always returns Either
class UsersRepositoryImpl implements UsersRepository {
  final dbHelper = DatabaseHelper();

  @override
  Future<Either<SettingsFailure, User>> createUser(
    User user, {
    String? createdBy,
  }) async {
    try {
      final db = await dbHelper.database;
      final map = user.toMap();
      if (createdBy != null) {
        map['created_by'] = createdBy;
      }
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
  Future<Either<SettingsFailure, List<User>>> getActiveUsers() async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query('users', where: 'is_active = 1');
      final users = maps.map((map) => User.fromMap(map)).toList();
      return Either.right(users);
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدمين: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User?>> getUserById(String userId) async {
    try {
      final db = await dbHelper.database;
      final maps =
          await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (maps.isEmpty) return const Either.right(null);
      return Either.right(User.fromMap(maps.first));
    } catch (e) {
      return Either.left(DatabaseSettingsFailure('فشل في جلب المستخدم: $e'));
    }
  }

  @override
  Future<Either<SettingsFailure, User?>> getUserByUsername(
      String username) async {
    try {
      final db = await dbHelper.database;
      final maps =
          await db.query('users', where: 'username = ?', whereArgs: [username]);
      if (maps.isEmpty) return const Either.right(null);
      return Either.right(User.fromMap(maps.first));
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
  Future<Either<SettingsFailure, User>> updatePermissions(
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
  Future<Either<SettingsFailure, User>> updateUser(User user) async {
    try {
      final db = await dbHelper.database;
      final map = user.toMap();
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
