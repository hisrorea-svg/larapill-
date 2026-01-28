import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../database/database_helper.dart';
import '../../data/datasources/local/notification_settings_local_datasource.dart';
import '../../data/datasources/local/pharmacy_settings_local_datasource.dart';
import '../../data/datasources/local/system_settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../domain/domain.dart';

/// Provider for UsersRepository
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl();
});

/// Provider for DatabaseHelper instance
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// ✅ صحيح: استخدام FutureProvider بدلاً من Provider
///
/// يعيد AsyncValue<SharedPreferences> ويتعامل مع الـ loading/error automatically
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Provider for SettingsRepository
///
/// يستخدم ref.watch مع FutureProvider ويستخرج القيمة بشكل صحيح
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);

  // ✅ صحيح: استخدام .valueOrNull للحصول على القيمة
  ref.watch(sharedPreferencesProvider);

  // إنشاء data sources
  final pharmacyDataSource = PharmacySettingsLocalDataSourceImpl(dbHelper);
  final systemDataSource = SystemSettingsLocalDataSourceImpl(dbHelper);

  // ✅ صحيح: استخراج SharedPreferences من AsyncValue
  final sharedPreferencesAsync = ref.watch(sharedPreferencesProvider);
  final notificationDataSource = NotificationSettingsLocalDataSourceImpl(
    sharedPreferencesAsync.valueOrNull,
  );

  return SettingsRepositoryImpl(
    notificationDataSource,
    pharmacyDataSource,
    systemDataSource,
  );
});

// ==================== Use Cases Providers ====================

/// Provider لـ GetUsersUseCase
final getUsersUseCaseProvider = Provider<GetUsersUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return GetUsersUseCase(repository);
});

/// Provider لـ GetUserByIdUseCase
final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return GetUserByIdUseCase(repository);
});

/// Provider لـ CreateUserUseCase
final createUserUseCaseProvider = Provider<CreateUserUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return CreateUserUseCase(repository);
});

/// Provider لـ UpdateUserUseCase
final updateUserUseCaseProvider = Provider<UpdateUserUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return UpdateUserUseCase(repository);
});

/// Provider لـ DeleteUserUseCase
final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return DeleteUserUseCase(repository);
});

/// Provider لـ ResetPasswordUseCase
final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

/// Provider لـ UpdateUserPermissionsUseCase
final updateUserPermissionsUseCaseProvider =
    Provider<UpdateUserPermissionsUseCase>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return UpdateUserPermissionsUseCase(repository);
});

/// Provider لـ GetPharmacySettingsUseCase
final getPharmacySettingsUseCaseProvider =
    Provider<GetPharmacySettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return GetPharmacySettingsUseCase(repository);
});

/// Provider لـ UpdatePharmacySettingsUseCase
final updatePharmacySettingsUseCaseProvider =
    Provider<UpdatePharmacySettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return UpdatePharmacySettingsUseCase(repository);
});

/// Provider لـ GetNotificationSettingsUseCase
final getNotificationSettingsUseCaseProvider =
    Provider<GetNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return GetNotificationSettingsUseCase(repository);
});

/// Provider لـ UpdateNotificationSettingsUseCase
final updateNotificationSettingsUseCaseProvider =
    Provider<UpdateNotificationSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return UpdateNotificationSettingsUseCase(repository);
});

// ==================== Async Providers ====================

/// Provider لجلب جميع المستخدمين النشطين
///
/// يستخدم AsyncValue لإدارة حالات التحميل/الخطأ/البيانات
final usersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final useCase = ref.watch(getUsersUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (users) => users,
  );
});

/// Provider لجلب مستخدم بواسطة ID
final userByIdProvider =
    FutureProvider.autoDispose.family<UserEntity?, String>((ref, userId) async {
  final useCase = ref.watch(getUserByIdUseCaseProvider);
  final result = await useCase(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
});

/// Provider لجلب إعدادات الصيدلية
final pharmacySettingsProvider =
    FutureProvider.autoDispose<PharmacySettingsEntity?>((ref) async {
  final useCase = ref.watch(getPharmacySettingsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});

/// Provider لجلب إعدادات الإشعارات
final notificationSettingsProvider =
    FutureProvider.autoDispose<NotificationSettingsEntity>((ref) async {
  final useCase = ref.watch(getNotificationSettingsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});
