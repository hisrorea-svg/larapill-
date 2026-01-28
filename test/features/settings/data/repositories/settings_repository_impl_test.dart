import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/settings/data/models/notification_settings_model.dart';
import 'package:larapill/features/settings/data/models/pharmacy_settings_model.dart';
import 'package:larapill/features/settings/data/models/system_settings_model.dart';
import 'package:larapill/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:larapill/features/settings/domain/entities/notification_settings_entity.dart';
import 'package:larapill/features/settings/data/datasources/local/notification_settings_local_datasource.dart';
import 'package:larapill/features/settings/data/datasources/local/pharmacy_settings_local_datasource.dart';
import 'package:larapill/features/settings/data/datasources/local/system_settings_local_datasource.dart';

// ============ Mock Implementations ============

class MockNotificationDataSource
    implements NotificationSettingsLocalDataSource {
  NotificationSettingsModel? _savedModel;
  final NotificationSettingsModel _defaultModel =
      const NotificationSettingsModel();

  void setSavedModel(NotificationSettingsModel model) {
    _savedModel = model;
  }

  @override
  Future<NotificationSettingsModel> getSettings() async {
    return _savedModel ?? _defaultModel;
  }

  @override
  Future<void> saveSettings(NotificationSettingsModel settings) async {
    _savedModel = settings;
  }

  @override
  Future<void> clearSettings() async {
    _savedModel = null;
  }
}

class MockPharmacyDataSource implements PharmacySettingsLocalDataSource {
  PharmacySettingsModel? _savedModel;

  void setSavedModel(PharmacySettingsModel model) {
    _savedModel = model;
  }

  @override
  Future<PharmacySettingsModel?> getSettings() async => _savedModel;

  @override
  Future<PharmacySettingsModel> saveSettings(
      PharmacySettingsModel settings) async {
    _savedModel = settings;
    return settings;
  }
}

class MockSystemDataSource implements SystemSettingsLocalDataSource {
  final Map<String, SystemSettingsModel> _settings = {};

  @override
  Future<SystemSettingsModel?> getSetting(String key) async => _settings[key];

  @override
  Future<SystemSettingsModel> setSetting(
    String key,
    String value, {
    String? description,
    String? category,
  }) async {
    final model = SystemSettingsModel(key: key, value: value);
    _settings[key] = model;
    return model;
  }

  @override
  Future<void> deleteSetting(String key) async {
    _settings.remove(key);
  }
}

void main() {
  group('SettingsRepositoryImpl', () {
    late MockNotificationDataSource mockNotificationDataSource;
    late MockPharmacyDataSource mockPharmacyDataSource;
    late MockSystemDataSource mockSystemDataSource;
    late SettingsRepositoryImpl repository;

    setUp(() {
      mockNotificationDataSource = MockNotificationDataSource();
      mockPharmacyDataSource = MockPharmacyDataSource();
      mockSystemDataSource = MockSystemDataSource();

      repository = SettingsRepositoryImpl(
        mockNotificationDataSource,
        mockPharmacyDataSource,
        mockSystemDataSource,
      );
    });

    group('getNotificationSettings', () {
      test('should return NotificationSettingsEntity when data source succeeds',
          () async {
        // Arrange
        const model = NotificationSettingsModel(
          expiryAlerts: false,
          lowStockAlerts: true,
          salesNotifications: true,
          systemNotifications: false,
          soundEnabled: true,
          expiryDays: 45,
        );
        mockNotificationDataSource.setSavedModel(model);

        // Act
        final result = await repository.getNotificationSettings();

        // Assert - unwrap Either
        result.fold(
          (failure) => fail('Expected Right but got Left: ${failure.message}'),
          (settings) {
            expect(settings, isA<NotificationSettingsEntity>());
            expect(settings.expiryAlerts, false);
            expect(settings.expiryDays, 45);
          },
        );
      });

      test('should return default settings when data source returns defaults',
          () async {
        // Act
        final result = await repository.getNotificationSettings();

        // Assert - unwrap Either
        result.fold(
          (failure) => fail('Expected Right but got Left: ${failure.message}'),
          (settings) {
            expect(settings, isA<NotificationSettingsEntity>());
            expect(settings.expiryDays, 30);
            expect(settings.soundEnabled, true);
          },
        );
      });
    });

    group('saveNotificationSettings', () {
      test('should save and return the same entity', () async {
        // Arrange
        const entity = NotificationSettingsEntity(
          expiryAlerts: true,
          lowStockAlerts: false,
          salesNotifications: true,
          systemNotifications: true,
          soundEnabled: false,
          expiryDays: 60,
        );

        // Act
        final result = await repository.saveNotificationSettings(entity);

        // Assert - unwrap Either
        result.fold(
          (failure) => fail('Expected Right but got Left: ${failure.message}'),
          (settings) {
            expect(settings, entity);
            expect(settings.expiryDays, 60);
          },
        );
      });

      test('should convert entity to model before saving', () async {
        // Arrange
        const entity = NotificationSettingsEntity(
          expiryAlerts: true,
          expiryDays: 30,
        );

        // Act
        await repository.saveNotificationSettings(entity);
        final savedModel = await mockNotificationDataSource.getSettings();

        // Assert
        expect(savedModel, isA<NotificationSettingsModel>());
      });
    });
  });
}
