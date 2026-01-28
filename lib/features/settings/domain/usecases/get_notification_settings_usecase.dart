import '../entities/notification_settings_entity.dart';
import '../repositories/settings_repository.dart';
import '../failures/settings_failure.dart';

/// Use Case لجلب إعدادات الإشعارات
class GetNotificationSettingsUseCase {
  final SettingsRepository _repository;

  const GetNotificationSettingsUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, NotificationSettingsEntity>> call() async {
    return await _repository.getNotificationSettings();
  }
}
