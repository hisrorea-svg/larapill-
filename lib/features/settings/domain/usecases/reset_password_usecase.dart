import '../../../auth/domain/entities/user.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Parameters لإعادة تعيين كلمة المرور
class ResetPasswordParams {
  final String userId;
  final String newPasswordHash;
  final bool forceChange;

  const ResetPasswordParams({
    required this.userId,
    required this.newPasswordHash,
    this.forceChange = true,
  });
}

/// Use Case لإعادة تعيين كلمة مرور المستخدم
class ResetPasswordUseCase {
  final UsersRepository _repository;

  const ResetPasswordUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, User>> call(ResetPasswordParams params) async {
    // التحقق من أن كلمة المرور ليست فارغة
    if (params.newPasswordHash.isEmpty) {
      return const Either.left(
          ValidationSettingsFailure('كلمة المرور لا يمكن أن تكون فارغة'));
    }

    // التحقق من وجود المستخدم
    final userResult = await _repository.getUserById(params.userId);

    return userResult.fold(
      (failure) => Either.left(failure),
      (user) async {
        if (user == null) {
          return const Either.left(UserNotFoundFailure());
        }

        // تحديث كلمة المرور
        return await _repository.updatePassword(
          params.userId,
          params.newPasswordHash,
          forceChange: params.forceChange,
        );
      },
    );
  }
}
