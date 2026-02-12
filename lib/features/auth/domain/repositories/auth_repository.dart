import '../entities/user.dart';
import '../failures/auth_failure.dart';
import '../../../../core/utils/either.dart';

/// Repository interface for authentication operations
///
/// This is the contract that data layer must implement
/// Pure domain layer - no implementation details
abstract class AuthRepository {
  /// Login with username and password
  Future<Either<AuthFailure, User>> login({
    required String username,
    required String password,
  });

  /// Logout current user
  Future<Either<AuthFailure, void>> logout();

  /// Get current authenticated user
  Future<Either<AuthFailure, User>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Change password for user
  Future<Either<AuthFailure, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  });
}
