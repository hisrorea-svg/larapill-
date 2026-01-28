import 'dart:math';
import '../entities/notification_entity.dart';
import '../entities/notification_type.dart';
import '../entities/notification_priority.dart';
import '../repositories/notification_repository.dart';

/// UseCase: إنشاء إشعار مبيعات
class CreateSaleNotificationUseCase {
  final NotificationRepository _repository;

  const CreateSaleNotificationUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call({
    required double amount,
    required String invoiceId,
  }) async {
    // التحقق من الصحة
    if (amount < 0) {
      throw ArgumentError('Amount cannot be negative');
    }
    if (invoiceId.isEmpty) {
      throw ArgumentError('Invoice ID cannot be empty');
    }

    // قاعدة العمل: تحديد الأولوية بناءً على المبلغ
    final priority = _determinePriority(amount);

    // إنشاء الإشعار
    final notification = NotificationEntity(
      id: _generateId(),
      title: 'مبيعة جديدة 💰',
      body: 'تم بيع منتجات بقيمة ${amount.toInt()} د.ع - فاتورة #$invoiceId',
      type: NotificationType.sales,
      priority: priority,
      createdAt: DateTime.now(),
      actionData: {
        'amount': amount,
        'invoiceId': invoiceId,
      },
    );

    await _repository.add(notification);
  }

  /// قاعدة العمل: تحديد الأولوية
  NotificationPriority _determinePriority(double amount) {
    if (amount > 500000) return NotificationPriority.high;
    if (amount > 100000) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  String _generateId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
