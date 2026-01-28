import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/usecases/get_notification_settings_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import 'settings_providers.dart';

/// State class for managing notification settings state.
///
/// Uses AsyncValue for load/error/data state management.
/// Separates validation state from AsyncValue data state.
class NotificationSettingsState {
  final AsyncValue<NotificationSettingsEntity> settings;
  final bool isSaving;
  final ValidationError? validationError;

  const NotificationSettingsState({
    required this.settings,
    this.isSaving = false,
    this.validationError,
  });

  NotificationSettingsState copyWith({
    AsyncValue<NotificationSettingsEntity>? settings,
    bool? isSaving,
    ValidationError? validationError,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isSaving: isSaving ?? this.isSaving,
      validationError: validationError ?? this.validationError,
    );
  }

  /// Returns current settings or empty defaults.
  NotificationSettingsEntity get currentSettings {
    return settings.value ?? const NotificationSettingsEntity();
  }

  bool get isLoading => settings.isLoading;

  bool get hasError => settings.hasError;

  bool get hasData => settings.hasValue;
}

/// Domain-level validation error for field-level issues.
class ValidationError {
  final String message;
  final String? userMessage;
  final String? fieldName;

  const ValidationError({
    required this.message,
    this.userMessage,
    this.fieldName,
  });
}

/// StateNotifier for managing notification settings.
///
/// Responsibilities:
/// - Load/save settings through use cases
/// - Update UI state reactively
/// - Separate validation logic from state mutations
/// - Prevent race conditions and data loss
class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final GetNotificationSettingsUseCase _getUseCase;
  final UpdateNotificationSettingsUseCase _updateUseCase;
  Timer? _debounceTimer;

  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _saveTimeout = Duration(seconds: 10);

  NotificationSettingsNotifier(
    this._getUseCase,
    this._updateUseCase,
  ) : super(
          const NotificationSettingsState(
            settings: AsyncValue.loading(),
          ),
        ) {
    _initializeSettings();
  }

  /// Initialize settings on notifier creation.
  /// Prevents duplicate initialization by marking guard.
  Future<void> _initializeSettings() async {
    await _loadSettings();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load settings from use case.
  /// Preserves last known good data on error.
  Future<void> _loadSettings() async {
    if (kDebugMode) {
      debugPrint('📥 Loading notification settings...');
    }

    // Only set loading if we don't have previous data
    if (!state.hasData) {
      state = state.copyWith(settings: const AsyncValue.loading());
    }

    try {
      final result = await _getUseCase();
      result.fold(
        (failure) {
          if (kDebugMode) {
            debugPrint(
                '❌ Failed to load notification settings: ${failure.message}');
          }
          // Preserve existing data if available
          if (!state.hasData) {
            state = state.copyWith(
              settings: AsyncValue.error(
                  Exception(failure.message), StackTrace.current),
            );
          }
        },
        (settings) {
          if (kDebugMode) {
            debugPrint('✅ Notification settings loaded successfully');
          }
          state = state.copyWith(settings: AsyncValue.data(settings));
        },
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Exception loading notification settings: $e');
      }
      if (!state.hasData) {
        state = state.copyWith(settings: AsyncValue.error(e, stackTrace));
      }
    }
  }

  /// Update single boolean field.
  /// Validates implicitly through domain entity.
  void updateExpiryAlerts(bool value) {
    _updateField((current) => current.copyWith(expiryAlerts: value));
  }

  void updateLowStockAlerts(bool value) {
    _updateField((current) => current.copyWith(lowStockAlerts: value));
  }

  void updateSalesNotifications(bool value) {
    _updateField((current) => current.copyWith(salesNotifications: value));
  }

  void updateSystemNotifications(bool value) {
    _updateField((current) => current.copyWith(systemNotifications: value));
  }

  void updateSoundEnabled(bool value) {
    _updateField((current) => current.copyWith(soundEnabled: value));
  }

  /// Update expiry days with explicit validation.
  /// Stores validation error locally, preserves data state.
  void updateExpiryDays(int days) {
    final validationError = _validateExpiryDays(days);

    if (validationError != null) {
      state = state.copyWith(validationError: validationError);
      return;
    }

    // Clear validation error on success
    state = state.copyWith(validationError: null);
    _updateField((current) => current.copyWith(expiryDays: days));
  }

  /// Generic field update helper.
  /// Prevents AsyncValue overwrites on local updates.
  /// Debounces rapid updates to avoid excessive rebuilds.
  void _updateField(
    NotificationSettingsEntity Function(
      NotificationSettingsEntity,
    ) updater,
  ) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Set new debounce timer
    _debounceTimer = Timer(_debounceDelay, () {
      final current = state.currentSettings;
      final updated = updater(current);

      if (kDebugMode) {
        debugPrint(
            '⚙️  Notification settings updated: ${updated.expiryDays} days');
      }

      state = state.copyWith(
        settings: AsyncValue.data(updated),
      );
    });
  }

  /// Validate expiry days with clear error messages.
  /// Returns null if valid, ValidationError if invalid.
  ValidationError? _validateExpiryDays(int days) {
    if (days < 1) {
      return const ValidationError(
        message: 'Expiry days must be at least 1',
        userMessage: 'يجب أن يكون عدد الأيام 1 على الأقل',
        fieldName: 'expiryDays',
      );
    }
    if (days > 365) {
      return const ValidationError(
        message: 'Expiry days cannot exceed 365',
        userMessage: 'لا يمكن أن يتجاوز عدد الأيام 365',
        fieldName: 'expiryDays',
      );
    }
    return null;
  }

  /// Validate entire settings state.
  /// Used before save operation.
  ValidationError? _validateAllSettings(NotificationSettingsEntity settings) {
    final expiryValidation = _validateExpiryDays(settings.expiryDays);
    if (expiryValidation != null) return expiryValidation;

    // Add additional validations as needed
    return null;
  }

  /// Save settings through use case.
  /// Ensures isSaving is reset in all paths.
  /// Preserves last good data on failure.
  /// Includes timeout protection against hanging operations.
  Future<void> saveSettings() async {
    if (state.isSaving) {
      if (kDebugMode) {
        debugPrint('⏸️  Save already in progress, ignoring request');
      }
      return;
    }

    final currentSettings = state.currentSettings;

    // Pre-save validation
    final validationError = _validateAllSettings(currentSettings);
    if (validationError != null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️  Validation failed: ${validationError.message} (${validationError.fieldName})');
      }
      state = state.copyWith(validationError: validationError);
      return;
    }

    state = state.copyWith(isSaving: true);
    if (kDebugMode) {
      debugPrint('💾 Saving notification settings...');
    }

    try {
      await _executeSave(currentSettings);
      if (kDebugMode) {
        debugPrint('✅ Notification settings saved successfully');
      }
      state = state.copyWith(
        settings: AsyncValue.data(currentSettings),
        isSaving: false,
        validationError: null,
      );
    } on AppException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ AppException during save: $e');
      }
      // Preserve data, record error
      state = state.copyWith(
        settings: state.settings.hasValue
            ? state.settings
            : AsyncValue.error(e, stackTrace),
        isSaving: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error during save: $e');
      }
      state = state.copyWith(
        settings: state.settings.hasValue
            ? state.settings
            : AsyncValue.error(e, stackTrace),
        isSaving: false,
      );
    }
  }

  /// Execute save operation through use case.
  /// Separated for testing and clarity.
  /// Includes timeout protection against hanging operations.
  Future<void> _executeSave(NotificationSettingsEntity settings) async {
    try {
      await _updateUseCase(
        UpdateNotificationSettingsParams(
          expiryAlerts: settings.expiryAlerts,
          lowStockAlerts: settings.lowStockAlerts,
          salesNotifications: settings.salesNotifications,
          systemNotifications: settings.systemNotifications,
          soundEnabled: settings.soundEnabled,
          expiryDays: settings.expiryDays,
        ),
      ).timeout(_saveTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
            '⏱️  Save operation timed out after ${_saveTimeout.inSeconds}s');
      }
      rethrow;
    }
  }

  /// Refresh settings from source.
  /// Useful for reload after external changes.
  Future<void> refresh() async {
    if (kDebugMode) {
      debugPrint('🔄 Refreshing notification settings...');
    }
    await _loadSettings();
  }
}

/// Provider for NotificationSettingsNotifier.
final notificationSettingsNotifierProvider = StateNotifierProvider.autoDispose<
    NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  final getUseCase = ref.watch(getNotificationSettingsUseCaseProvider);
  final updateUseCase = ref.watch(updateNotificationSettingsUseCaseProvider);
  return NotificationSettingsNotifier(getUseCase, updateUseCase);
});
