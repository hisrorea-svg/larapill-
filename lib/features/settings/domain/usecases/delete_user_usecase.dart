import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either, Unit
import '../failures/settings_failure.dart';

/// Use Case لحذف مستخدم
class DeleteUserUseCase {
  final UsersRepository _repository;

  const DeleteUserUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, Unit>> call(String userId) async {
    // التحقق من وجود المستخدم
    final userResult = await _repository.getUserById(userId);

    return userResult.fold(
      (failure) => Either.left(failure),
      (user) async {
        if (user == null) {
          return const Either.left(UserNotFoundFailure());
        }

        // منع حذف المستخدم admin
        if (user.isAdmin) {
          return const Either.left(
              PermissionDeniedFailure('لا يمكن حذف مدير النظام'));
        }

        // منع حذف المستخدم إذا كان اسم المستخدم 'admin'
        if (user.username == 'admin') {
          return const Either.left(
              PermissionDeniedFailure('لا يمكن حذف مدير النظام'));
        }

        return await _repository.deleteUser(userId);
      },
    );
  }
}
