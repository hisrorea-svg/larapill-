import '../repositories/notification_repository.dart';

/// UseCase: تعليم إشعار كمقروء
class MarkNotificationAsReadUseCase {
  final NotificationRepository _repository;

  const MarkNotificationAsReadUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call(String notificationId) async {
    if (notificationId.isEmpty) {
      throw ArgumentError('Notification ID cannot be empty');
    }

    await _repository.markAsRead(notificationId);
  }
}
