import '../repositories/auth_repository.dart';
import '../failures/auth_failure.dart';
import '../../../../core/utils/either.dart';

/// Logout Use Case
///
/// Handles user logout and session cleanup
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  /// Execute logout
  Future<Either<AuthFailure, void>> execute() {
    return _repository.logout();
  }
}
