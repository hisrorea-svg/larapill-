import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
// Using legacy User for now until migration is complete
import '../../domain/entities/user.dart';

// ================================
// Repository Provider
// ================================
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// ================================
// Use Case Providers
// ================================
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.read(authRepositoryProvider));
});

// ================================
// State Providers
// ================================
final currentUserProvider = FutureProvider<User?>((ref) async {
  final useCase = ref.watch(getCurrentUserUseCaseProvider);
  final result = await useCase.execute();

  return result.fold(
    (failure) => null,
    (user) => user,
  );
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user != null;
});
