import '../entities/notification_settings_entity.dart';
import '../repositories/settings_repository.dart';
import '../failures/settings_failure.dart';

/// Parameters for updating notification settings.
class UpdateNotificationSettingsParams {
  final bool expiryAlerts;
  final bool lowStockAlerts;
  final bool salesNotifications;
  final bool systemNotifications;
  final bool soundEnabled;
  final int expiryDays;

  const UpdateNotificationSettingsParams({
    required this.expiryAlerts,
    required this.lowStockAlerts,
    required this.salesNotifications,
    required this.systemNotifications,
    required this.soundEnabled,
    required this.expiryDays,
  });
}

/// Use case for updating notification settings
class UpdateNotificationSettingsUseCase {
  final SettingsRepository _repository;

  const UpdateNotificationSettingsUseCase(this._repository);

  /// Execute the use case to update notification settings
  Future<Either<SettingsFailure, NotificationSettingsEntity>> call(
    UpdateNotificationSettingsParams params,
  ) async {
    // Validation
    if (params.expiryDays <= 0 || params.expiryDays > 365) {
      return const Either.left(ValidationSettingsFailure(
          'أيام التنبيه يجب أن تكون بين 1 و 365'));
    }

    final settings = NotificationSettingsEntity(
      expiryAlerts: params.expiryAlerts,
      lowStockAlerts: params.lowStockAlerts,
      salesNotifications: params.salesNotifications,
      systemNotifications: params.systemNotifications,
      soundEnabled: params.soundEnabled,
      expiryDays: params.expiryDays,
    );

    return await _repository.saveNotificationSettings(settings);
  }
}
