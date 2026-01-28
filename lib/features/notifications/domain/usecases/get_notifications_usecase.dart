import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

/// UseCase: الحصول على جميع الإشعارات
class GetNotificationsUseCase {
  final NotificationRepository _repository;

  const GetNotificationsUseCase(this._repository);

  /// تنفيذ UseCase
  Future<List<NotificationEntity>> call() async {
    return await _repository.getAll();
  }

  /// مراقبة الإشعارات لحظياً
  Stream<List<NotificationEntity>> watch() {
    return _repository.watchAll();
  }
}
