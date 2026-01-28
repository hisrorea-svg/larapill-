import 'dart:math';
import '../entities/notification_entity.dart';
import '../entities/notification_type.dart';
import '../entities/notification_priority.dart';
import '../repositories/notification_repository.dart';

/// UseCase: إنشاء إشعار انتهاء صلاحية قريب
class CreateNearExpiryNotificationUseCase {
  final NotificationRepository _repository;

  const CreateNearExpiryNotificationUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call({
    required String productName,
    required DateTime expiryDate,
    required String productId,
  }) async {
    // التحقق من الصحة
    if (productName.isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    // حساب الأيام المتبقية
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

    // قاعدة العمل: تحديد الأولوية بناءً على الأيام المتبقية
    final priority = _determinePriority(daysUntilExpiry);

    // إنشاء الإشعار
    final notification = NotificationEntity(
      id: _generateId(),
      title: 'تحذير: انتهاء صلاحية قريب 📅',
      body: 'المنتج "$productName" ينتهي خلال $daysUntilExpiry يوم',
      type: NotificationType.inventory,
      priority: priority,
      createdAt: DateTime.now(),
      actionData: {
        'productName': productName,
        'expiryDate': expiryDate.toIso8601String(),
        'productId': productId,
        'daysUntilExpiry': daysUntilExpiry,
      },
    );

    await _repository.add(notification);
  }

  /// قاعدة العمل: تحديد الأولوية
  NotificationPriority _determinePriority(int daysUntilExpiry) {
    if (daysUntilExpiry <= 7) return NotificationPriority.urgent;
    if (daysUntilExpiry <= 30) return NotificationPriority.high;
    return NotificationPriority.medium;
  }

  String _generateId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
