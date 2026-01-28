import '../entities/user_entity.dart';
import '../failures/settings_failure.dart';
import 'settings_repository.dart'; // For Either and Unit

/// واجهة Repository لإدارة المستخدمين
///
/// يستخدم Either للتعامل مع الأخطاء بطريقة typed
/// يجب أن يتم تنفيذه في data layer
abstract class UsersRepository {
  /// جلب جميع المستخدمين النشطين
  Future<Either<SettingsFailure, List<UserEntity>>> getActiveUsers();

  /// جلب مستخدم بواسطة ID
  Future<Either<SettingsFailure, UserEntity?>> getUserById(String userId);

  /// جلب مستخدم بواسطة اسم المستخدم
  Future<Either<SettingsFailure, UserEntity?>> getUserByUsername(
      String username);

  /// إنشاء مستخدم جديد
  Future<Either<SettingsFailure, UserEntity>> createUser(UserEntity user,
      {String? createdBy});

  /// تحديث مستخدم موجود
  Future<Either<SettingsFailure, UserEntity>> updateUser(UserEntity user);

  /// حذف مستخدم
  Future<Either<SettingsFailure, Unit>> deleteUser(String userId);

  /// تحديث كلمة مرور المستخدم
  Future<Either<SettingsFailure, UserEntity>> updatePassword(
    String userId,
    String newPasswordHash, {
    bool forceChange = false,
  });

  /// تحديث صلاحيات المستخدم
  Future<Either<SettingsFailure, UserEntity>> updatePermissions(
    String userId,
    List<String> permissions,
  );

  /// التحقق من وجود مستخدم باسم مستخدم معين
  Future<Either<SettingsFailure, bool>> usernameExists(String username);
}
