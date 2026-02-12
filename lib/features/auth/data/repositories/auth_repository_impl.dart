import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../../../core/utils/either.dart';
import '../services/authentication_service.dart';
import '../services/password_service.dart';

/// Repository implementation using new focused services
/// Replaces direct UserService calls with service layer
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<AuthFailure, User>> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await AuthenticationService.login(username, password);

      if (result['success'] == true) {
        final user = result['user'] as User;
        return Right(user);
      } else {
        final error = result['error'] as String;
        return Left(_mapErrorToFailure(error));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      final result = await AuthenticationService.logout();

      if (result['success'] == true) {
        return const Right(null);
      } else {
        return Left(UnknownFailure(result['error']));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, User>> getCurrentUser() async {
    try {
      final user = await AuthenticationService.getCurrentUser();

      if (user != null) {
        return Right(user);
      } else {
        return const Left(SessionExpiredFailure());
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await AuthenticationService.isAuthenticated();
  }

  @override
  Future<Either<AuthFailure, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final result = await PasswordService.changePassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (result['success'] == true) {
        return const Right(null);
      } else {
        final error = result['error'] as String;
        return Left(_mapErrorToFailure(error));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Map error string to typed failure
  /// Supports both error codes and Arabic messages for backward compatibility
  AuthFailure _mapErrorToFailure(String error) {
    final lowerError = error.toLowerCase();

    // Check error codes first (preferred method)
    if (lowerError.contains('invalid_password') ||
        lowerError.contains('wrong_password') ||
        error.contains('كلمة المرور')) {
      return const InvalidCredentialsFailure();
    } else if (lowerError.contains('user_not_found') ||
        error.contains('المستخدم غير موجود')) {
      return const UserNotFoundFailure();
    } else if (lowerError.contains('account_locked')) {
      return const AccountLockedFailure();
    } else if (lowerError.contains('account_disabled') ||
        error.contains('غير مفعل')) {
      return const AccountDisabledFailure();
    } else if (lowerError.contains('network') || error.contains('الاتصال')) {
      return const NetworkFailure();
    } else if (lowerError.contains('database') ||
        lowerError.contains('sqlite')) {
      return const DatabaseFailure();
    } else {
      return UnknownFailure(error);
    }
  }
}
