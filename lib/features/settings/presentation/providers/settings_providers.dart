import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database_helper.dart';
import '../../data/datasources/local/notification_settings_local_datasource.dart';
import '../../data/datasources/local/pharmacy_settings_local_datasource.dart';
import '../../data/datasources/local/system_settings_local_datasource.dart';
import '../../data/repositories/settings_dependencies.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../../../features/auth/domain/models/user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/usecases/get_notification_settings_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';

// ==================== Data Layer Providers ====================

/// Provides NotificationSettingsLocalDataSource instance.
final notificationLocalDataSourceProvider =
    Provider<NotificationSettingsLocalDataSource>((ref) {
  return SettingsDependencies.createNotificationDataSourceFromHive();
});

/// Provides PharmacySettingsLocalDataSource instance.
final pharmacyLocalDataSourceProvider =
    FutureProvider<PharmacySettingsLocalDataSource>((ref) {
  final db = DatabaseHelper();
  return SettingsDependencies.createPharmacyDataSource(db);
});

/// Provides SystemSettingsLocalDataSource instance.
final systemLocalDataSourceProvider =
    FutureProvider<SystemSettingsLocalDataSource>((ref) {
  final db = DatabaseHelper();
  return SettingsDependencies.createSystemDataSource(db);
});

// ==================== Repository Provider ====================

/// Provides SettingsRepository instance.
///
/// This is the main entry point for accessing settings functionality.
/// All settings operations go through this repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = DatabaseHelper();
  return SettingsDependencies.createRepositoryFromHive(db);
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
  return UsersRepositoryImpl();
});

/// Provider for active users list.
/// Used by settings screen for user management.

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
