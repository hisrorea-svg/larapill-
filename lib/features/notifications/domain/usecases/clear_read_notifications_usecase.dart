import '../repositories/notification_repository.dart';

/// UseCase: حذف الإشعارات المقروءة
class ClearReadNotificationsUseCase {
  final NotificationRepository _repository;

  const ClearReadNotificationsUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call() async {
    await _repository.clearRead();
  }
}
