# Presentation Layer - Settings Feature

## 📁 البنية

```
presentation/
├── providers/
│   └── settings_providers.dart    # Riverpod Providers
├── screens/
│   └── settings_screen.dart       # الشاشة الرئيسية
├── widgets/
│   ├── notification_settings_dialog.dart
│   ├── reports_settings_dialog.dart
│   ├── security_settings_dialog.dart
│   └── system_log_dialog.dart
└── utils/
    └── user_entity_mapper.dart    # تحويل UserEntity إلى Map للعرض
```

## ✅ التحويلات المنفذة

### 1. تحويل `_loadUsersData()` إلى استخدام Use Cases

#### قبل التحويل:
```dart
// ❌ خطأ: استدعاء DatabaseHelper مباشرة
Future<List<Map<String, dynamic>>> _loadUsersData() async {
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final users = await db.query('users', ...);
  // ...
}
```

#### بعد التحويل:
```dart
// ✅ صحيح: استخدام Riverpod Provider مع AsyncValue
Consumer(
  builder: (context, ref, child) {
    final usersAsync = ref.watch(usersProvider);
    
    return usersAsync.when(
      data: (users) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => ErrorWidget(...),
    );
  },
)
```

### 2. استخدام AsyncValue

الكود الآن يستخدم `AsyncValue` من Riverpod لإدارة الحالات:
- **Loading**: عرض `CircularProgressIndicator`
- **Data**: عرض قائمة المستخدمين
- **Error**: عرض رسالة خطأ مع زر إعادة المحاولة

### 3. إزالة استدعاءات DatabaseHelper المباشرة

تم إزالة جميع استدعاءات `DatabaseHelper` من `_loadUsersData()` واستبدالها بـ:
- `usersProvider` - FutureProvider يستخدم `GetUsersUseCase`
- `UserEntityMapper` - لتحويل `UserEntity` إلى `Map` للعرض

## 🔌 Providers

### FutureProvider للمستخدمين

```dart
final usersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final useCase = ref.watch(getUsersUseCaseProvider);
  return await useCase();
});
```

### Use Case Providers

جميع Use Cases لها Providers:
- `getUsersUseCaseProvider`
- `getUserByIdUseCaseProvider`
- `createUserUseCaseProvider`
- `updateUserUseCaseProvider`
- `deleteUserUseCaseProvider`
- `resetPasswordUseCaseProvider`
- `updateUserPermissionsUseCaseProvider`

## 🛠️ Utility Classes

### UserEntityMapper

يستخدم لتحويل `UserEntity` (Domain Model) إلى `Map<String, dynamic>` للعرض في UI:

```dart
final usersMap = UserEntityMapper.toDisplayMapList(users);
```

**السبب**: الكود الحالي في `_buildUserItem` يتوقع `Map`، لذلك نحتاج إلى تحويل `UserEntity` إلى `Map` مؤقتاً.

**ملاحظة**: يمكن تحسين هذا لاحقاً بتحويل `_buildUserItem` لاستخدام `UserEntity` مباشرة.

## ⚠️ ملاحظات مهمة

### 1. Repository Implementation مطلوب

**المشكلة الحالية**: `usersRepositoryProvider` و `settingsRepositoryProvider` يرميان `UnimplementedError` لأن Repository Implementation غير موجودة بعد.

**الحل المطلوب**: يجب إنشاء:
- `lib/features/settings/data/repositories/users_repository_impl.dart`
- `lib/features/settings/data/repositories/settings_repository_impl.dart`

### 2. تحديث Providers بعد إنشاء Repository Implementation

بعد إنشاء Repository Implementation، قم بتحديث:

```dart
// في settings_providers.dart
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  // TODO: استبدل هذا بـ:
  // final dao = ref.watch(userDaoProvider);
  // return UsersRepositoryImpl(dao);
  throw UnimplementedError('...');
});
```

## 📝 الخطوات التالية

1. ✅ **تم**: إنشاء Domain Layer
2. ✅ **تم**: إنشاء Providers
3. ✅ **تم**: تحويل `_loadUsersData()` لاستخدام Use Cases
4. ⏳ **قادم**: إنشاء Data Layer (Repository Implementations)
5. ⏳ **قادم**: تحويل باقي الدوال (`_addNewUser`, `_editUser`, إلخ)
6. ⏳ **قادم**: تحسين `_buildUserItem` لاستخدام `UserEntity` مباشرة

## 🔄 التدفق الحالي

```
Widget (settings_screen.dart)
    ↓
ref.watch(usersProvider)
    ↓
FutureProvider<List<UserEntity>>
    ↓
getUsersUseCaseProvider
    ↓
GetUsersUseCase
    ↓
UsersRepository (Interface)
    ↓
❌ UsersRepositoryImpl (غير موجود بعد)
```

## ✅ Checklist

- [x] إنشاء Providers file
- [x] إنشاء UserEntityMapper
- [x] تحويل `_loadUsersData()` لاستخدام Use Cases
- [x] استخدام AsyncValue للحالات
- [x] إزالة استدعاءات DatabaseHelper المباشرة
- [ ] إنشاء Repository Implementations
- [ ] تحويل باقي الدوال
- [ ] تحسين `_buildUserItem` لاستخدام `UserEntity` مباشرة
