import 'package:equatable/equatable.dart';

/// كيان إعدادات الإشعارات في Domain Layer
///
/// هذا الكيان خالٍ تماماً من أي Flutter imports أو data layer dependencies
/// يستخدم Equatable للمقارنة بين الكيانات
class NotificationSettingsEntity extends Equatable {
  final bool expiryAlerts;
  final bool lowStockAlerts;
  final bool salesNotifications;
  final bool systemNotifications;
  final bool soundEnabled;
  final int expiryDays;

  const NotificationSettingsEntity({
    this.expiryAlerts = true,
    this.lowStockAlerts = true,
    this.salesNotifications = true,
    this.systemNotifications = true,
    this.soundEnabled = true,
    this.expiryDays = 30,
  });

  @override
  List<Object?> get props => [
        expiryAlerts,
        lowStockAlerts,
        salesNotifications,
        systemNotifications,
        soundEnabled,
        expiryDays,
      ];

  /// إنشاء نسخة محدثة من الكيان
  NotificationSettingsEntity copyWith({
    bool? expiryAlerts,
    bool? lowStockAlerts,
    bool? salesNotifications,
    bool? systemNotifications,
    bool? soundEnabled,
    int? expiryDays,
  }) {
    return NotificationSettingsEntity(
      expiryAlerts: expiryAlerts ?? this.expiryAlerts,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      salesNotifications: salesNotifications ?? this.salesNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      expiryDays: expiryDays ?? this.expiryDays,
    );
  }

  /// التحقق من أن أي إشعارات مفعلة
  bool get hasAnyNotificationsEnabled =>
      expiryAlerts ||
      lowStockAlerts ||
      salesNotifications ||
      systemNotifications;

  /// التحقق من صحة إعدادات انتهاء الصلاحية
  bool get isValidExpiryDays => expiryDays > 0 && expiryDays <= 365;

  @override
  String toString() {
    return 'NotificationSettingsEntity{'
        'expiryAlerts: $expiryAlerts, '
        'lowStockAlerts: $lowStockAlerts, '
        'salesNotifications: $salesNotifications, '
        'systemNotifications: $systemNotifications, '
        'soundEnabled: $soundEnabled, '
        'expiryDays: $expiryDays}';
  }
}
