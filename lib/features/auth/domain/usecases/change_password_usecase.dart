import '../repositories/auth_repository.dart';
import '../failures/auth_failure.dart';
import '../../../../core/utils/either.dart';

/// Change Password Use Case
///
/// Handles password change for authenticated users
class ChangePasswordUseCase {
  final AuthRepository _repository;

  const ChangePasswordUseCase(this._repository);

  /// Execute password change
  Future<Either<AuthFailure, void>> execute({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
