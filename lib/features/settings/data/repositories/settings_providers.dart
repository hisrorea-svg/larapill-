import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../database/database_helper.dart';
import '../datasources/local/notification_settings_local_datasource.dart';
import '../datasources/local/pharmacy_settings_local_datasource.dart';
import '../datasources/local/system_settings_local_datasource.dart';
import '../repositories/settings_dependencies.dart';
import '../../domain/repositories/settings_repository.dart';

// ==================== Data Layer Providers ====================

/// Provides NotificationSettingsLocalDataSource instance.
final notificationLocalDataSourceProvider =
    FutureProvider<NotificationSettingsLocalDataSource>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsDependencies.createNotificationDataSource(prefs);
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
///
/// Usage:
/// ```dart
/// final repository = await ref.watch(settingsRepositoryProvider.future);
/// final settings = await repository.getNotificationSettings();
/// ```
final settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final db = DatabaseHelper();
  return SettingsDependencies.createRepository(prefs, db);
});

// ==================== Use Case Providers ====================
// These would be defined in domain/usecases but are shown here for reference

/// Get notification settings.
///
/// Automatically handles loading, error, and data states.
final getNotificationSettingsProvider = FutureProvider((ref) async {
  final repository = await ref.watch(settingsRepositoryProvider.future);
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
  final repository = await ref.watch(settingsRepositoryProvider.future);
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
  final repository = await ref.watch(settingsRepositoryProvider.future);
  final result = await repository.getSystemSetting(key);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (value) => value,
  );
});

// ==================== State Notifier Providers ====================
// These are already implemented in presentation layer

// Example: NotificationSettingsNotifierProvider (already exists)
// - Handles state management for notification settings UI
// - Provides updateExpiryAlerts(), updateExpiryDays(), saveSettings()
// - Uses AsyncValue for loading/error/data states

// Example: PharmacySettingsNotifierProvider (should follow same pattern)
// - Handles state management for pharmacy settings form
// - Provides update methods for each field
// - Validates before save

// Example: SystemSettingsNotifierProvider (should follow same pattern)
// - Handles state management for system settings
// - Provides key-value update methods

// ==================== Widget Integration Example ====================
// Usage in your UI/Widgets:

/*
class NotificationSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get notifier for state management
    final notifier = ref.watch(notificationSettingsNotifierProvider.notifier);
    final state = ref.watch(notificationSettingsNotifierProvider);
    
    return state.settings.when(
      data: (settings) => Column(
        children: [
          SwitchListTile(
            title: Text('Expiry Alerts'),
            value: settings.expiryAlerts,
            onChanged: (value) => notifier.updateExpiryAlerts(value),
          ),
          SwitchListTile(
            title: Text('Sound Enabled'),
            value: settings.soundEnabled,
            onChanged: (value) => notifier.updateSoundEnabled(value),
          ),
          ElevatedButton(
            onPressed: state.isSaving ? null : () => notifier.saveSettings(),
            child: state.isSaving 
              ? CircularProgressIndicator()
              : Text('Save Settings'),
          ),
        ],
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }
}
*/

// ==================== Testing Integration ====================
// Usage in your tests:

/*
test('Get notification settings from repository', () async {
  final container = ProviderContainer(
    overrides: [
      // Mock the SharedPreferences
      // notificationLocalDataSourceProvider.overrideWithValue(
      //   MockNotificationDataSource(),
      // ),
    ],
  );
  
  final repository = await container.read(settingsRepositoryProvider.future);
  final settings = await repository.getNotificationSettings();
  
  expect(settings.expiryDays, 30);
});
*/
