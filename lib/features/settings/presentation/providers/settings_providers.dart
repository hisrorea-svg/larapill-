import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/drift/daos/daos.dart';
import '../../data/repositories/settings_dependencies.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/usecases/get_notification_settings_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';

// ==================== Repository Provider ====================

/// Provides SettingsRepository instance.
///
/// Architecture: Repository → DAO/HiveStorage → Storage
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dao = ref.watch(settingsDriftDaoProvider);
  return SettingsDependencies.createRepository(dao);
});

// ==================== Use Case Providers ====================

/// Provider for GetNotificationSettingsUseCase.
final getNotificationSettingsUseCaseProvider =
    Provider<GetNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return GetNotificationSettingsUseCase(repository);
});

/// Provider for UpdateNotificationSettingsUseCase.
final updateNotificationSettingsUseCaseProvider =
    Provider<UpdateNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return UpdateNotificationSettingsUseCase(repository);
});

// ==================== Async Value Providers ====================

/// Get notification settings.
///
/// Automatically handles loading, error, and data states.
final getNotificationSettingsProvider = FutureProvider((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  final result = await repository.getNotificationSettings();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});

/// Get pharmacy settings.
///
/// Returns null if pharmacy settings haven't been configured yet.
final getPharmacySettingsProvider = FutureProvider((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  final result = await repository.getPharmacySettings();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});

/// Get system setting by key.
///
/// Returns the value or defaultValue if not found.
final getSystemSettingProvider = FutureProvider.family<String?, String>((
  ref,
  String key,
) async {
  final repository = ref.watch(settingsRepositoryProvider);
  final result = await repository.getSystemSetting(key);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (value) => value,
  );
});

// ==================== Users Providers ====================

/// Provides UsersRepository instance.
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dao = ref.watch(usersDriftDaoProvider);
  return UsersRepositoryImpl(dao);
});

/// Provider for active users list.
/// Used by settings screen for user management.
final usersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final repository = ref.watch(usersRepositoryProvider);
  final result = await repository.getActiveUsers();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (users) => users,
  );
});
