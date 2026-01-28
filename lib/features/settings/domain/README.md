# Domain Layer - Settings Feature

## 📁 البنية

```
domain/
├── entities/              # الكيانات (Domain Models)
│   ├── user_entity.dart
│   ├── pharmacy_settings_entity.dart
│   └── notification_settings_entity.dart
├── repositories/          # واجهات Repositories
│   ├── users_repository.dart
│   └── settings_repository.dart
└── usecases/             # Use Cases (Business Logic)
    ├── get_users_usecase.dart
    ├── get_user_by_id_usecase.dart
    ├── create_user_usecase.dart
    ├── update_user_usecase.dart
    ├── delete_user_usecase.dart
    ├── reset_password_usecase.dart
    ├── update_user_permissions_usecase.dart
    ├── get_pharmacy_settings_usecase.dart
    ├── update_pharmacy_settings_usecase.dart
    ├── get_notification_settings_usecase.dart
    └── update_notification_settings_usecase.dart
```

## 🎯 المبادئ

### ✅ Domain Layer خالٍ من:
- ❌ Flutter imports (`package:flutter/...`)
- ❌ Data layer imports (`database/...`, `services/...`)
- ❌ External dependencies (ماعدا Dart core libraries)

### ✅ Domain Layer يحتوي على:
- ✅ Entities (Domain Models)
- ✅ Repository Interfaces (Abstract Classes)
- ✅ Use Cases (Business Logic)
- ✅ Domain-specific exceptions (يمكن استخدام AppException من core)

## 📦 Entities

### UserEntity
كيان المستخدم في Domain Layer. يحتوي على:
- معلومات المستخدم الأساسية
- الدور (UserRole enum)
- الصلاحيات
- حالة النشاط

### PharmacySettingsEntity
كيان إعدادات الصيدلية. يحتوي على:
- معلومات الصيدلية (اسم، ترخيص، إلخ)
- معلومات الاتصال
- العنوان
- المعلومات الضريبية

### NotificationSettingsEntity
كيان إعدادات الإشعارات. يحتوي على:
- إعدادات التنبيهات المختلفة
- إعدادات الصوت
- عدد أيام التنبيه

## 🔌 Repositories

### UsersRepository
واجهة لإدارة المستخدمين:
- `getActiveUsers()` - جلب جميع المستخدمين النشطين
- `getUserById()` - جلب مستخدم بواسطة ID
- `createUser()` - إنشاء مستخدم جديد
- `updateUser()` - تحديث مستخدم
- `deleteUser()` - حذف مستخدم
- `updatePassword()` - تحديث كلمة المرور
- `updatePermissions()` - تحديث الصلاحيات

### SettingsRepository
واجهة لإدارة الإعدادات:
- `getPharmacySettings()` - جلب إعدادات الصيدلية
- `savePharmacySettings()` - حفظ إعدادات الصيدلية
- `getNotificationSettings()` - جلب إعدادات الإشعارات
- `saveNotificationSettings()` - حفظ إعدادات الإشعارات
- `getSystemSetting()` - جلب إعداد نظامي
- `setSystemSetting()` - حفظ إعداد نظامي

## 🎯 Use Cases

### Users Use Cases

#### GetUsersUseCase
جلب جميع المستخدمين النشطين.

```dart
final useCase = GetUsersUseCase(repository);
final users = await useCase();
```

#### CreateUserUseCase
إنشاء مستخدم جديد.

```dart
final useCase = CreateUserUseCase(repository);
final user = await useCase(CreateUserParams(
  username: 'john',
  fullName: 'John Doe',
  passwordHash: 'hashed_password',
  role: UserRole.cashier,
));
```

#### UpdateUserUseCase
تحديث مستخدم موجود.

```dart
final useCase = UpdateUserUseCase(repository);
final updatedUser = await useCase(UpdateUserParams(
  userId: 'user_123',
  fullName: 'John Updated',
  email: 'john@example.com',
));
```

#### DeleteUserUseCase
حذف مستخدم.

```dart
final useCase = DeleteUserUseCase(repository);
await useCase('user_123');
```

#### ResetPasswordUseCase
إعادة تعيين كلمة مرور المستخدم.

```dart
final useCase = ResetPasswordUseCase(repository);
await useCase(ResetPasswordParams(
  userId: 'user_123',
  newPasswordHash: 'new_hashed_password',
));
```

### Settings Use Cases

#### GetPharmacySettingsUseCase
جلب إعدادات الصيدلية.

```dart
final useCase = GetPharmacySettingsUseCase(repository);
final settings = await useCase();
```

#### UpdatePharmacySettingsUseCase
تحديث إعدادات الصيدلية.

```dart
final useCase = UpdatePharmacySettingsUseCase(repository);
final updated = await useCase(UpdatePharmacySettingsParams(
  nameAr: 'صيدلية جديدة',
  phone: '123456789',
));
```

## 📝 ملاحظات مهمة

1. **لا تستورد Flutter في Domain Layer**: جميع الكيانات والـ Use Cases خالية من Flutter imports.

2. **استخدم AppException**: يمكن استخدام `AppException` من `core/exceptions` في Use Cases.

3. **Repository Implementation**: يجب تنفيذ Repositories في `data/` layer.

4. **Use Cases هي Business Logic**: جميع قواعد الأعمال يجب أن تكون في Use Cases.

5. **Entities هي Domain Models**: لا تستخدم Data Models في Domain Layer.

## 🔄 التدفق

```
Presentation Layer (Widgets)
    ↓
Use Cases (Domain)
    ↓
Repository Interfaces (Domain)
    ↓
Repository Implementations (Data)
    ↓
Data Sources (Database/API)
```

## ✅ Checklist

- [x] Entities خالية من Flutter imports
- [x] Repository Interfaces محددة
- [x] Use Cases لكل عملية
- [x] Validation في Use Cases
- [x] Error handling باستخدام AppException
- [x] Documentation كاملة
