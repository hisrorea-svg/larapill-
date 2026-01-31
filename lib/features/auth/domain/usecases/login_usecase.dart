import '../repositories/auth_repository.dart';
import '../failures/auth_failure.dart';
import '../models/user.dart';
import '../../../../core/utils/either.dart';

/// Login Use Case
///
/// Handles user authentication with username and password
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  /// Execute login
  Future<Either<AuthFailure, User>> execute({
    required String username,
    required String password,
  }) {
    return _repository.login(username: username, password: password);
  }
}
