# Settings Feature - Quick Reference Guide

## 📚 File Organization

### Data Layer Structure
```
data/
├── datasources/local/
│   ├── notification_settings_local_datasource.dart     # SharedPreferences
│   ├── pharmacy_settings_local_datasource.dart         # SQLite
│   └── system_settings_local_datasource.dart           # SQLite key-value
├── models/
│   ├── notification_settings_model.dart                # DTO + conversions
│   ├── pharmacy_settings_model.dart                    # DTO + conversions
│   └── system_settings_model.dart                      # DTO + conversions
└── repositories/
    ├── settings_repository_impl.dart                   # Main repository
    ├── settings_dependencies.dart                      # DI factory
    └── settings_providers.dart                         # Riverpod providers
```

---

## 🚀 Quick Start

### 1. Create Repository
```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../database/database_helper.dart';
import 'settings_dependencies.dart';

final prefs = await SharedPreferences.getInstance();
final db = DatabaseHelper();
final repository = SettingsDependencies.createRepository(prefs, db);
```

### 2. Get Settings
```dart
// Notification settings (SharedPreferences)
final notification = await repository.getNotificationSettings();
print('Expiry days: ${notification.expiryDays}');

// Pharmacy settings (Database)
final pharmacy = await repository.getPharmacySettings();
print('Pharmacy name: ${pharmacy?.nameAr}');

// System setting (Database key-value)
final theme = await repository.getSystemSetting('theme', defaultValue: 'light');
```

### 3. Save Settings
```dart
// Update notification
final updated = notification.copyWith(expiryDays: 60);
await repository.saveNotificationSettings(updated);

// Update pharmacy
final updatedPharmacy = pharmacy?.copyWith(nameAr: 'صيدليتي');
await repository.savePharmacySettings(updatedPharmacy);

// Set system setting
await repository.setSystemSetting(
  'theme',
  'dark',
  category: 'ui',
  description: 'Application theme',
);
```

---

## 🔄 Data Flow

### Typical Flow
```
UI Widget
  ↓
StateNotifier (Presentation)
  ↓ (AsyncValue)
Use Case (Domain)
  ↓
Repository (Data)
  ↓ (catch exceptions)
Data Source
  ↓
Model ←→ Storage (SharedPreferences / SQLite)
  ↓
toEntity() → Entity (Domain) → UI
```

### Example: Save Notification Settings

```
User clicks "Save"
  ↓
NotificationSettingsNotifier.saveSettings()
  ↓
UpdateNotificationSettingsUseCase()
  ↓
SettingsRepository.saveNotificationSettings(entity)
  ↓
NotificationSettingsModel.fromEntity(entity)
  ↓
NotificationSettingsLocalDataSource.saveSettings(model)
  ↓
SharedPreferences.setString(...) / JSON encode
  ↓
State updated with AsyncValue.data(entity)
  ↓
UI rebuilds with new settings
```

---

## 🧪 Testing

### Mock Data Source
```dart
class MockNotificationDataSource extends Mock
    implements NotificationSettingsLocalDataSource {}

void setUp() {
  final mockDataSource = MockNotificationDataSource();
  when(mockDataSource.getSettings()).thenAnswer(
    (_) async => const NotificationSettingsModel(),
  );
  
  final repository = SettingsRepositoryImpl(
    mockDataSource,
    mockPharmacyDataSource,
    mockSystemDataSource,
  );
}
```

### Test Repository
```dart
test('returns entity when data source succeeds', () async {
  final result = await repository.getNotificationSettings();
  
  expect(result, isA<NotificationSettingsEntity>());
  expect(result.expiryDays, 30);
});
```

---

## ⚠️ Common Mistakes

### ❌ Don't
```dart
// ❌ Don't access SharedPreferences directly in UI
final prefs = await SharedPreferences.getInstance();
final value = prefs.getString('key');

// ❌ Don't mix Model and Entity
NotificationSettingsEntity entity = model;  // Wrong!

// ❌ Don't bypass repository
final db = await DatabaseHelper().database;
final row = await db.query(...);  // Wrong!
```

### ✅ Do
```dart
// ✅ Use repository
final settings = await repository.getNotificationSettings();

// ✅ Convert properly
NotificationSettingsEntity entity = model.toEntity();

// ✅ Always go through repository
final settings = await repository.getNotificationSettings();
```

---

## 🔌 Integration Points

### With Notifiers
```dart
// In NotificationSettingsNotifier
class NotificationSettingsNotifier extends StateNotifier<...> {
  NotificationSettingsNotifier(
    this._getUseCase,
    this._updateUseCase,
  );
  
  Future<void> refresh() async {
    // Use case calls repository automatically
    await _getUseCase();
  }
}
```

### With Use Cases
```dart
// In domain/usecases
class GetNotificationSettingsUseCase {
  final SettingsRepository _repository;
  
  Future<NotificationSettingsEntity> call() async {
    // Already returns entity (domain object)
    return _repository.getNotificationSettings();
  }
}
```

### With Riverpod
```dart
// In settings_providers.dart
final getNotificationSettingsProvider = FutureProvider((ref) async {
  final repository = await ref.watch(settingsRepositoryProvider.future);
  return repository.getNotificationSettings();
});

// In UI
final settings = ref.watch(getNotificationSettingsProvider);
```

---

## 📊 Architecture Rules

| Layer | Responsibility | Can Access |
|-------|----------------|------------|
| UI/Widget | Display & user interaction | Notifier, Entity |
| Presentation (Notifier) | State management | Use Case, AsyncValue |
| Domain (Use Case) | Business logic | Repository interface |
| Data (Repository) | Orchestration | Data Sources, Models |
| Data (Data Source) | Storage operations | SharedPreferences, DB |

---

## 🎯 Key Concepts

### Model vs Entity
- **Model**: Data Transfer Object (DTO) for serialization/deserialization
- **Entity**: Domain object representing business logic

### Data Source
- Handles ONE storage mechanism (SharedPreferences or Database)
- Converts between storage format and Model
- Throws domain exceptions

### Repository
- Orchestrates data sources
- Converts Model → Entity
- Delegates to data sources

### Immutability
All models and entities are immutable:
```dart
// Safe updates
final updated = entity.copyWith(expiryDays: 60);
// Original unchanged
assert(entity.expiryDays == 30);
```

---

## 🐛 Debugging

### Enable Logging
```dart
// All data sources log operations
// Check console for: ✅ Success, ❌ Errors

// In NotificationSettingsNotifier already included:
debugPrint('📧 Loading notification settings...');
debugPrint('✅ Loaded successfully');
```

### Trace Data Flow
```dart
// 1. Check UI calls notifier
// 2. Check notifier calls use case
// 3. Check use case calls repository
// 4. Check repository calls data source
// 5. Check data source accesses storage
```

---

## 📦 Dependencies

### Provided by Project
- `flutter_riverpod` - State management
- `shared_preferences` - Simple storage
- `sqflite` - Database
- `faker` - Test data (if included)

### Models Need
```dart
import 'package:flutter/foundation.dart';  // @immutable
```

---

## ✅ Pre-Production Checklist

- [ ] All data sources have error handling
- [ ] All tests passing
- [ ] No direct access to SharedPreferences outside data layer
- [ ] No direct access to DatabaseHelper outside data layer
- [ ] Models properly convert to/from storage format
- [ ] Entities converted from models before returning to domain
- [ ] No business logic in data sources
- [ ] All Riverpod providers tested
- [ ] Documentation up to date
- [ ] No console errors or warnings

---

## 📞 Common Issues & Solutions

### Issue: "Failed to load pharmacy settings"
**Cause**: Database not initialized
**Fix**: Ensure `DatabaseHelper().database` is called before repository

### Issue: "Invalid notification settings format"
**Cause**: Corrupted SharedPreferences data
**Fix**: Clear app cache or uninstall/reinstall

### Issue: Model not converting to Entity
**Cause**: Missing `toEntity()` method
**Fix**: Check model has `toEntity()` implementation

### Issue: Tests failing with Mock
**Cause**: Mock not configured with `when().thenAnswer()`
**Fix**: See testing section above

---

Generated: 2025-01-19
Status: ✅ Production Ready
