import '../../../auth/domain/models/user.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Parameters لتحديث مستخدم
class UpdateUserParams {
  final String userId;
  final String? fullName;
  final String? email;
  final String? phone;
  final UserRole? role;
  final List<String>? permissions;
  final bool? isActive;

  const UpdateUserParams({
    required this.userId,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.permissions,
    this.isActive,
  });
}

/// Use Case لتحديث مستخدم موجود
class UpdateUserUseCase {
  final UsersRepository _repository;

  const UpdateUserUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, User>> call(UpdateUserParams params) async {
    // جلب المستخدم الحالي
    final currentUserResult = await _repository.getUserById(params.userId);

    return currentUserResult.fold(
      (failure) => Either.left(failure),
      (currentUser) async {
        if (currentUser == null) {
          return const Either.left(UserNotFoundFailure());
        }

        // إنشاء User محدث
        final updatedUser = currentUser.copyWith(
          fullName: params.fullName,
          email: params.email,
          phone: params.phone,
          role: params.role,
          permissions: params.permissions,
          isActive: params.isActive,
          updatedAt: DateTime.now(),
        );

        return await _repository.updateUser(updatedUser);
      },
    );
  }
}
