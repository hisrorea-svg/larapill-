import '../entities/user_entity.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Parameters لتحديث الصلاحيات
class UpdateUserPermissionsParams {
  final String userId;
  final List<String> permissions;

  const UpdateUserPermissionsParams({
    required this.userId,
    required this.permissions,
  });
}

/// Use Case لتحديث صلاحيات المستخدم
class UpdateUserPermissionsUseCase {
  final UsersRepository _repository;

  const UpdateUserPermissionsUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, UserEntity>> call(
      UpdateUserPermissionsParams params) async {
    // التحقق من وجود المستخدم
    final userResult = await _repository.getUserById(params.userId);

    return userResult.fold(
      (failure) => Either.left(failure),
      (user) async {
        if (user == null) {
          return const Either.left(UserNotFoundFailure());
        }

        // منع تحديث صلاحيات admin
        if (user.isAdmin) {
          return const Either.left(PermissionDeniedFailure(
              'لا يمكن تحديث صلاحيات مدير النظام'));
        }

        return await _repository.updatePermissions(
          params.userId,
          params.permissions,
        );
      },
    );
  }
}
