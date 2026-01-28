# تحويل NotificationSettingsDialog إلى Riverpod StateNotifier

## 📋 نظرة عامة

تم تحويل `NotificationSettingsDialog` من استخدام `SharedPreferences` مباشرة إلى استخدام Riverpod StateNotifier مع Clean Architecture.

## 🔄 التحويلات

### قبل التحويل

```dart
// ❌ خطأ: استخدام SharedPreferences مباشرة في Widget
class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  bool _expiryAlerts = true;
  bool _isLoading = true;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expiryAlerts = prefs.getBool('expiry_alerts') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('expiry_alerts', _expiryAlerts);
  }
}
```

### بعد التحويل

```dart
// ✅ صحيح: استخدام StateNotifier مع Use Cases
class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  Future<void> saveSettings() async {
    await _updateUseCase(UpdateNotificationSettingsParams(...));
  }
}

// Widget يستخدم Consumer
class NotificationSettingsDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsNotifierProvider);
    // ...
  }
}
```

## 📁 الملفات الجديدة

### 1. NotificationSettingsNotifier
**الملف**: `lib/features/settings/presentation/providers/notification_settings_notifier.dart`

**المميزات**:
- ✅ StateNotifier لإدارة الحالة
- ✅ استخدام AsyncValue للحالات (loading/error/data)
- ✅ استخدام Use Cases للحفظ والتحميل
- ✅ Fallback إلى SharedPreferences مؤقتاً (حتى يتم إنشاء Repository Implementation)
- ✅ معالجة أخطاء احترافية باستخدام AppException
- ✅ Validation للبيانات

**الحالة**:
```dart
class NotificationSettingsState {
  final AsyncValue<NotificationSettingsEntity> settings;
  final bool isSaving;
}
```

**الوظائف**:
- `updateExpiryAlerts(bool)` - تحديث تنبيهات انتهاء الصلاحية
- `updateLowStockAlerts(bool)` - تحديث تنبيهات نقص المخزون
- `updateSalesNotifications(bool)` - تحديث إشعارات المبيعات
- `updateSystemNotifications(bool)` - تحديث إشعارات النظام
- `updateSoundEnabled(bool)` - تحديث تفعيل الصوت
- `updateExpiryDays(int)` - تحديث عدد أيام التنبيه (مع validation)
- `saveSettings()` - حفظ الإعدادات
- `refresh()` - إعادة تحميل الإعدادات

### 2. NotificationSettingsDialog (محدث)
**الملف**: `lib/features/settings/widgets/notification_settings_dialog.dart`

**التغييرات**:
- ✅ تحويل من `StatefulWidget` إلى `ConsumerWidget`
- ✅ استخدام `ref.watch(notificationSettingsNotifierProvider)`
- ✅ استخدام `AsyncValue.when()` للحالات
- ✅ إزالة جميع استدعاءات `SharedPreferences`
- ✅ إزالة `setState()` - الحالة الآن في StateNotifier

## 🎯 المميزات

### 1. فصل المنطق عن UI
- ✅ المنطق في `NotificationSettingsNotifier`
- ✅ UI في `NotificationSettingsDialog`
- ✅ لا يوجد منطق تجاري في Widget

### 2. استخدام AsyncValue
```dart
state.settings.when(
  data: (settings) => Widget(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stackTrace) => ErrorWidget(...),
)
```

### 3. معالجة الأخطاء
- ✅ استخدام AppException
- ✅ رسائل خطأ واضحة للمستخدم
- ✅ إمكانية إعادة المحاولة

### 4. Validation
```dart
void updateExpiryDays(int days) {
  if (days < 1 || days > 365) {
    state = state.copyWith(
      settings: AsyncValue.error(
        ValidationException(...),
      ),
    );
    return;
  }
  // ...
}
```

## 🔌 Provider

```dart
final notificationSettingsNotifierProvider =
    StateNotifierProvider.autoDispose<NotificationSettingsNotifier,
        NotificationSettingsState>((ref) {
  final getUseCase = ref.watch(getNotificationSettingsUseCaseProvider);
  final updateUseCase = ref.watch(updateNotificationSettingsUseCaseProvider);
  return NotificationSettingsNotifier(getUseCase, updateUseCase);
});
```

## 📝 الاستخدام

### في Widget

```dart
class NotificationSettingsDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(notificationSettingsNotifierProvider.notifier);
    final state = ref.watch(notificationSettingsNotifierProvider);

    return AlertDialog(
      content: state.settings.when(
        data: (settings) => Switch(
          value: settings.expiryAlerts,
          onChanged: (value) => notifier.updateExpiryAlerts(value),
        ),
        loading: () => CircularProgressIndicator(),
        error: (error, stackTrace) => ErrorWidget(...),
      ),
      actions: [
        ElevatedButton(
          onPressed: state.isSaving ? null : () => notifier.saveSettings(),
          child: state.isSaving 
            ? CircularProgressIndicator() 
            : Text('حفظ'),
        ),
      ],
    );
  }
}
```

## ⚠️ ملاحظات مهمة

### 1. Fallback إلى SharedPreferences
حالياً، Notifier يستخدم SharedPreferences مباشرة كـ fallback عندما يكون Repository Implementation غير موجود. هذا مؤقت وسيتم إزالته بعد إنشاء Repository Implementation.

### 2. Use Cases
Notifier يحاول استخدام Use Cases أولاً، وإذا فشل (UnimplementedError)، يستخدم SharedPreferences مباشرة.

### 3. AutoDispose
Provider يستخدم `autoDispose` لضمان تنظيف الموارد تلقائياً عند عدم الاستخدام.

## ✅ Checklist

- [x] إنشاء NotificationSettingsNotifier
- [x] إنشاء NotificationSettingsState
- [x] تحديث Widget لاستخدام ConsumerWidget
- [x] استخدام AsyncValue للحالات
- [x] إزالة SharedPreferences من Widget
- [x] إضافة Validation
- [x] إضافة معالجة أخطاء
- [ ] إنشاء Repository Implementation (قادم)
- [ ] إزالة Fallback إلى SharedPreferences (بعد إنشاء Repository)

## 🔄 التدفق

```
Widget (ConsumerWidget)
    ↓
ref.watch(notificationSettingsNotifierProvider)
    ↓
NotificationSettingsNotifier
    ↓
Use Cases (GetNotificationSettingsUseCase, UpdateNotificationSettingsUseCase)
    ↓
Repository (SettingsRepository)
    ↓
❌ Repository Implementation (غير موجود بعد - يستخدم SharedPreferences مؤقتاً)
```

## 📚 المراجع

- [Riverpod Documentation](https://riverpod.dev/)
- [StateNotifier Documentation](https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/StateNotifier-class.html)
- [Domain Layer README](../../domain/README.md)
