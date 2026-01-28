import 'package:flutter/foundation.dart';

import '../../domain/entities/notification_settings_entity.dart';

/// DTO (Data Transfer Object) for Notification Settings.
///
/// Responsible for:
/// - Serialization/deserialization (JSON, Map)
/// - Conversion to domain entity
/// - Immutability and copyWith pattern
@immutable
class NotificationSettingsModel {
  final bool expiryAlerts;
  final bool lowStockAlerts;
  final bool salesNotifications;
  final bool systemNotifications;
  final bool soundEnabled;
  final int expiryDays;

  const NotificationSettingsModel({
    this.expiryAlerts = true,
    this.lowStockAlerts = true,
    this.salesNotifications = true,
    this.systemNotifications = true,
    this.soundEnabled = true,
    this.expiryDays = 30,
  });

  /// Create from Map (database row or JSON).
  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      expiryAlerts:
          (map['expiryAlerts'] ?? map['expiry_alerts']) as bool? ?? true,
      lowStockAlerts:
          (map['lowStockAlerts'] ?? map['low_stock_alerts']) as bool? ?? true,
      salesNotifications:
          (map['salesNotifications'] ?? map['sales_notifications']) as bool? ??
              true,
      systemNotifications: (map['systemNotifications'] ??
              map['system_notifications']) as bool? ??
          true,
      soundEnabled:
          (map['soundEnabled'] ?? map['sound_enabled']) as bool? ?? true,
      expiryDays: (map['expiryDays'] ?? map['expiry_days']) as int? ?? 30,
    );
  }

  /// Convert to Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'expiryAlerts': expiryAlerts,
      'lowStockAlerts': lowStockAlerts,
      'salesNotifications': salesNotifications,
      'systemNotifications': systemNotifications,
      'soundEnabled': soundEnabled,
      'expiryDays': expiryDays,
    };
  }

  /// Convert to domain entity.
  NotificationSettingsEntity toEntity() {
    return NotificationSettingsEntity(
      expiryAlerts: expiryAlerts,
      lowStockAlerts: lowStockAlerts,
      salesNotifications: salesNotifications,
      systemNotifications: systemNotifications,
      soundEnabled: soundEnabled,
      expiryDays: expiryDays,
    );
  }

  /// Create model from entity.
  factory NotificationSettingsModel.fromEntity(
    NotificationSettingsEntity entity,
  ) {
    return NotificationSettingsModel(
      expiryAlerts: entity.expiryAlerts,
      lowStockAlerts: entity.lowStockAlerts,
      salesNotifications: entity.salesNotifications,
      systemNotifications: entity.systemNotifications,
      soundEnabled: entity.soundEnabled,
      expiryDays: entity.expiryDays,
    );
  }

  /// Create a copy with optional field replacements.
  NotificationSettingsModel copyWith({
    bool? expiryAlerts,
    bool? lowStockAlerts,
    bool? salesNotifications,
    bool? systemNotifications,
    bool? soundEnabled,
    int? expiryDays,
  }) {
    return NotificationSettingsModel(
      expiryAlerts: expiryAlerts ?? this.expiryAlerts,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      salesNotifications: salesNotifications ?? this.salesNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      expiryDays: expiryDays ?? this.expiryDays,
    );
  }

  @override
  String toString() {
    return 'NotificationSettingsModel('
        'expiryAlerts: $expiryAlerts, '
        'lowStockAlerts: $lowStockAlerts, '
        'salesNotifications: $salesNotifications, '
        'systemNotifications: $systemNotifications, '
        'soundEnabled: $soundEnabled, '
        'expiryDays: $expiryDays)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsModel &&
          runtimeType == other.runtimeType &&
          expiryAlerts == other.expiryAlerts &&
          lowStockAlerts == other.lowStockAlerts &&
          salesNotifications == other.salesNotifications &&
          systemNotifications == other.systemNotifications &&
          soundEnabled == other.soundEnabled &&
          expiryDays == other.expiryDays;

  @override
  int get hashCode =>
      expiryAlerts.hashCode ^
      lowStockAlerts.hashCode ^
      salesNotifications.hashCode ^
      systemNotifications.hashCode ^
      soundEnabled.hashCode ^
      expiryDays.hashCode;
}
