import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/settings/data/models/notification_settings_model.dart';
import 'package:larapill/features/settings/domain/entities/notification_settings_entity.dart';

void main() {
  group('NotificationSettingsModel', () {
    group('fromMap', () {
      test('should create model from map with all fields', () {
        // Arrange
        final map = {
          'expiryAlerts': false,
          'lowStockAlerts': true,
          'salesNotifications': false,
          'systemNotifications': true,
          'soundEnabled': false,
          'expiryDays': 45,
        };

        // Act
        final model = NotificationSettingsModel.fromMap(map);

        // Assert
        expect(model.expiryAlerts, false);
        expect(model.lowStockAlerts, true);
        expect(model.salesNotifications, false);
        expect(model.systemNotifications, true);
        expect(model.soundEnabled, false);
        expect(model.expiryDays, 45);
      });

      test('should use default values for missing fields', () {
        // Arrange
        final map = <String, dynamic>{};

        // Act
        final model = NotificationSettingsModel.fromMap(map);

        // Assert
        expect(model.expiryAlerts, true);
        expect(model.lowStockAlerts, true);
        expect(model.soundEnabled, true);
        expect(model.expiryDays, 30);
      });

      test('should handle database column names (snake_case)', () {
        // Arrange
        final map = {
          'expiry_alerts': false,
          'low_stock_alerts': true,
          'sound_enabled': false,
          'expiry_days': 60,
        };

        // Act
        final model = NotificationSettingsModel.fromMap(map);

        // Assert
        expect(model.expiryAlerts, false);
        expect(model.lowStockAlerts, true);
        expect(model.soundEnabled, false);
        expect(model.expiryDays, 60);
      });
    });

    group('toMap', () {
      test('should convert model to map', () {
        // Arrange
        const model = NotificationSettingsModel(
          expiryAlerts: false,
          lowStockAlerts: true,
          expiryDays: 45,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['expiryAlerts'], false);
        expect(map['lowStockAlerts'], true);
        expect(map['expiryDays'], 45);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        // Arrange
        const model = NotificationSettingsModel(
          expiryAlerts: false,
          expiryDays: 50,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<NotificationSettingsEntity>());
        expect(entity.expiryAlerts, false);
        expect(entity.expiryDays, 50);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        // Arrange
        const entity = NotificationSettingsEntity(
          expiryAlerts: false,
          expiryDays: 55,
        );

        // Act
        final model = NotificationSettingsModel.fromEntity(entity);

        // Assert
        expect(model.expiryAlerts, false);
        expect(model.expiryDays, 55);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        const original = NotificationSettingsModel(
          expiryAlerts: true,
          expiryDays: 30,
        );

        // Act
        final copy = original.copyWith(expiryDays: 60);

        // Assert
        expect(copy.expiryAlerts, true);
        expect(copy.expiryDays, 60);
        expect(original.expiryDays, 30); // Original unchanged
      });

      test('should preserve fields not in copyWith', () {
        // Arrange
        const original = NotificationSettingsModel(
          expiryAlerts: false,
          lowStockAlerts: true,
          soundEnabled: false,
        );

        // Act
        final copy = original.copyWith(expiryAlerts: true);

        // Assert
        expect(copy.expiryAlerts, true);
        expect(copy.lowStockAlerts, true);
        expect(copy.soundEnabled, false);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        // Arrange
        const model1 = NotificationSettingsModel(
          expiryAlerts: true,
          expiryDays: 30,
        );
        const model2 = NotificationSettingsModel(
          expiryAlerts: true,
          expiryDays: 30,
        );

        // Assert
        expect(model1, model2);
      });

      test('should not be equal when fields differ', () {
        // Arrange
        const model1 = NotificationSettingsModel(expiryDays: 30);
        const model2 = NotificationSettingsModel(expiryDays: 60);

        // Assert
        expect(model1, isNot(model2));
      });
    });
  });
}
