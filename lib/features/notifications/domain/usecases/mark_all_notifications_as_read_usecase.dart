import '../repositories/notification_repository.dart';

/// UseCase: تعليم جميع الإشعارات كمقروءة
class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository _repository;

  const MarkAllNotificationsAsReadUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call() async {
    await _repository.markAllAsRead();
  }
}
