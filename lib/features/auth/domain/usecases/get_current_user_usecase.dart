import '../repositories/auth_repository.dart';
import '../failures/auth_failure.dart';
import '../models/user.dart';
import '../../../../core/utils/either.dart';

/// Get Current User Use Case
///
/// Retrieves the currently authenticated user
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  /// Execute get current user
  Future<Either<AuthFailure, User>> execute() {
    return _repository.getCurrentUser();
  }
}
