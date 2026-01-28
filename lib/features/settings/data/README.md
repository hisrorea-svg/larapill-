# Settings Repository - Production-Ready Implementation

## Architecture Overview

This implementation follows Clean Architecture principles with clear separation of concerns:

```
Domain Layer (Interface)
       ↓
Repository Pattern (SettingsRepository)
       ↓
Data Layer
  ├── Data Sources (Local)
  │   ├── NotificationSettingsLocalDataSource
  │   ├── PharmacySettingsLocalDataSource
  │   └── SystemSettingsLocalDataSource
  ├── Models (DTOs)
  │   ├── NotificationSettingsModel
  │   ├── PharmacySettingsModel
  │   └── SystemSettingsModel
  └── Repository Implementation
       └── SettingsRepositoryImpl
```

## Key Design Patterns

### 1. Data Source Abstraction
Each storage mechanism has its own data source:
- **NotificationSettingsLocalDataSource**: Handles SharedPreferences
- **PharmacySettingsLocalDataSource**: Handles SQLite database
- **SystemSettingsLocalDataSource**: Handles key-value database

Benefits:
- Testability: Mock each data source independently
- Maintainability: Clear responsibilities
- Flexibility: Easy to swap implementations

### 2. Model-Entity Separation
```dart
// Data Layer (Model)
class NotificationSettingsModel {
  final bool expiryAlerts;
  final int expiryDays;
  
  // Conversion methods
  NotificationSettingsEntity toEntity() { ... }
  factory NotificationSettingsModel.fromEntity(NotificationSettingsEntity entity) { ... }
}

// Domain Layer (Entity)
class NotificationSettingsEntity {
  final bool expiryAlerts;
  final int expiryDays;
  
  // Pure domain logic only
}
```

Benefits:
- Domain logic is independent of storage
- Easy to evolve data layer without affecting domain
- Models can include storage-specific serialization

### 3. Dependency Injection
```dart
class SettingsDependencies {
  static SettingsRepository createRepository(
    SharedPreferences prefs,
    DatabaseHelper databaseHelper,
  ) {
    // All dependencies created here
  }
}
```

Benefits:
- Centralized dependency management
- Easy to test with mock dependencies
- Clear dependency graph

### 4. Error Handling
All data sources throw domain-level exceptions:
```dart
throw CacheException('Failed to load settings', ...)
throw DatabaseException('Failed to save settings', ...)
```

These are caught and handled by use cases, not the UI.

## Testing Approach

### Unit Testing Data Sources
```dart
test('NotificationSettingsLocalDataSource returns default when not found', () async {
  final prefs = SharedPreferences.getInstance();
  final dataSource = NotificationSettingsLocalDataSourceImpl(prefs);
  
  final result = await dataSource.getSettings();
  
  expect(result.expiryDays, 30);
  expect(result.soundEnabled, true);
});
```

### Unit Testing Repository
```dart
test('SettingsRepositoryImpl converts model to entity', () async {
  final mockDataSource = MockNotificationSettingsLocalDataSource();
  when(mockDataSource.getSettings())
      .thenAnswer((_) async => NotificationSettingsModel());
  
  final repository = SettingsRepositoryImpl(mockDataSource, ...);
  final result = await repository.getNotificationSettings();
  
  expect(result, isA<NotificationSettingsEntity>());
});
```

### Integration Testing
```dart
test('Full settings flow: save and retrieve', () async {
  final prefs = await SharedPreferences.getInstance();
  final databaseHelper = DatabaseHelper();
  
  final repository = SettingsDependencies.createRepository(
    prefs,
    databaseHelper,
  );
  
  final settings = PharmacySettingsEntity(nameAr: 'الصيدلية');
  await repository.savePharmacySettings(settings);
  
  final retrieved = await repository.getPharmacySettings();
  expect(retrieved?.nameAr, 'الصيدلية');
});
```

## Migration Guide

### Before (Tightly Coupled)
```dart
class SettingsRepositoryImpl {
  Future<Void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final db = await DatabaseHelper().database;
    // Mix of concerns
  }
}
```

### After (Clean Architecture)
```dart
class SettingsRepositoryImpl implements SettingsRepository {
  final NotificationSettingsLocalDataSource _notificationLocal;
  final PharmacySettingsLocalDataSource _pharmacyLocal;
  
  SettingsRepositoryImpl(this._notificationLocal, this._pharmacyLocal);
  
  Future<NotificationSettingsEntity> saveNotificationSettings(...) async {
    final model = NotificationSettingsModel.fromEntity(settings);
    await _notificationLocal.saveSettings(model);
    return settings;
  }
}
```

## Usage Example

```dart
// In your use case or Riverpod provider:
final settingsRepositoryProvider = FutureProvider((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final db = DatabaseHelper();
  
  return SettingsDependencies.createRepository(prefs, db);
});

// Usage:
final repository = await ref.watch(settingsRepositoryProvider.future);
final settings = await repository.getNotificationSettings();
```

## Production Checklist

- [x] Data sources separated by storage mechanism
- [x] Models with fromMap/toMap/toEntity conversions
- [x] Error handling with domain exceptions
- [x] Dependency injection ready
- [x] No infrastructure leakage to domain layer
- [x] Immutable models with copyWith
- [x] Comprehensive documentation
- [ ] Unit tests for all data sources
- [ ] Unit tests for repository
- [ ] Integration tests for full flow
- [ ] Performance tests for large datasets

## Future Improvements

1. **Caching**: Add in-memory cache to reduce database calls
2. **Pagination**: For system settings with many records
3. **Sync**: Implement cloud sync for pharmacy settings
4. **Encryption**: Encrypt sensitive settings in SharedPreferences
5. **Versioning**: Support schema migration for database settings
