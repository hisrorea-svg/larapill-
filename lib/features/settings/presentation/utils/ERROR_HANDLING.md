# معالجة الأخطاء في Settings Feature

## 📋 نظرة عامة

تم تطبيق معالجة أخطاء احترافية باستخدام `AppException` pattern في جميع عمليات Settings Feature.

## 🎯 المبادئ

### 1. استخدام Custom Exceptions

جميع الأخطاء يتم تحويلها إلى `AppException` أو أحد أنواعها الفرعية:

- `DatabaseException` - أخطاء قاعدة البيانات
- `DatabaseConstraintException` - قيود قاعدة البيانات (UNIQUE, FOREIGN_KEY)
- `ValidationException` - أخطاء التحقق من البيانات
- `BusinessRuleException` - أخطاء قواعد الأعمال
- `NotFoundException` - العنصر غير موجود
- `FileException` - أخطاء الملفات
- `UnexpectedException` - أخطاء غير متوقعة

### 2. استخدام convertToAppException

للأخطاء غير المتوقعة، يتم استخدام `convertToAppException` لتحويلها تلقائياً:

```dart
catch (e, stackTrace) {
  final appException = convertToAppException(e, stackTrace: stackTrace);
  SettingsErrorHandler.handleError(context, appException);
}
```

### 3. معالجة كل حالة خطأ بشكل مناسب

كل نوع خطأ له معالجة مناسبة:

```dart
try {
  // العملية
} on sqflite.DatabaseException catch (e, stackTrace) {
  // معالجة أخطاء قاعدة البيانات
  SettingsErrorHandler.handleError(
    context,
    DatabaseException(
      'وصف الخطأ',
      userMessage: 'رسالة للمستخدم',
      originalError: e,
      stackTrace: stackTrace,
      operation: 'update',
      tableName: 'users',
    ),
  );
} on ValidationException catch (e, stackTrace) {
  // معالجة أخطاء التحقق
  SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
} on BusinessRuleException catch (e, stackTrace) {
  // معالجة أخطاء قواعد الأعمال
  SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
} on AppException catch (e, stackTrace) {
  // معالجة باقي أنواع AppException
  SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
} catch (e, stackTrace) {
  // معالجة الأخطاء غير المتوقعة
  final appException = convertToAppException(e, stackTrace: stackTrace);
  SettingsErrorHandler.handleError(context, appException, stackTrace: stackTrace);
}
```

## 🛠️ SettingsErrorHandler

### الوظائف المتوفرة

#### 1. handleError
معالجة خطأ وعرض رسالة للمستخدم:

```dart
SettingsErrorHandler.handleError(
  context,
  error,
  stackTrace: stackTrace,
  onRetry: () {
    // إعادة المحاولة
  },
);
```

#### 2. getErrorMessage
الحصول على رسالة الخطأ فقط:

```dart
final message = SettingsErrorHandler.getErrorMessage(error);
```

#### 3. handleAsyncOperation
معالجة عملية async مع loading state:

```dart
await SettingsErrorHandler.handleAsyncOperation(
  context: context,
  operation: () async {
    // العملية
  },
  onSuccess: () {
    // عند النجاح
  },
  onError: (exception) {
    // عند الخطأ (اختياري)
  },
);
```

## 📝 أمثلة الاستخدام

### مثال 1: إنشاء نسخة احتياطية

```dart
Future<void> _createBackup() async {
  setState(() => _isLoading = true);
  try {
    final dbHelper = DatabaseHelper();
    final result = await dbHelper.createBackup();
    if (result['success'] == true) {
      _showSnackBar('تم إنشاء النسخة الاحتياطية بنجاح', AppColors.success);
    } else {
      throw DatabaseException(
        'فشل إنشاء النسخة الاحتياطية',
        userMessage: 'فشل إنشاء النسخة الاحتياطية. يرجى المحاولة مرة أخرى.',
        operation: 'backup',
      );
    }
  } on sqflite.DatabaseException catch (e, stackTrace) {
    SettingsErrorHandler.handleError(
      context,
      DatabaseException(
        'خطأ في قاعدة البيانات',
        userMessage: 'حدث خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.',
        originalError: e,
        stackTrace: stackTrace,
        operation: 'backup',
      ),
    );
  } on AppException catch (e, stackTrace) {
    SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
  } catch (e, stackTrace) {
    final appException = convertToAppException(e, stackTrace: stackTrace);
    SettingsErrorHandler.handleError(context, appException, stackTrace: stackTrace);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### مثال 2: تحديث مستخدم مع Validation

```dart
Future<void> _editUser(Map<String, dynamic> user) async {
  try {
    // التحقق من صحة البيانات
    if (nameController.text.trim().isEmpty) {
      throw ValidationException(
        'الاسم الكامل مطلوب',
        userMessage: 'الرجاء إدخال الاسم الكامل',
        fieldName: 'full_name',
      );
    }

    // تنفيذ العملية
    await db.update('users', {...});
    
    _showSnackBar('تم التحديث بنجاح', AppColors.success);
  } on ValidationException catch (e, stackTrace) {
    SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
  } on DatabaseException catch (e, stackTrace) {
    SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
  } catch (e, stackTrace) {
    final appException = convertToAppException(e, stackTrace: stackTrace);
    SettingsErrorHandler.handleError(context, appException, stackTrace: stackTrace);
  }
}
```

### مثال 3: إضافة مستخدم مع معالجة UNIQUE constraint

```dart
try {
  await db.insert('users', {...});
} on sqflite.DatabaseException catch (e, stackTrace) {
  if (e.toString().contains('UNIQUE constraint')) {
    SettingsErrorHandler.handleError(
      context,
      DatabaseConstraintException(
        'اسم المستخدم موجود مسبقاً',
        userMessage: 'اسم المستخدم موجود مسبقاً. يرجى استخدام اسم آخر.',
        originalError: e,
        stackTrace: stackTrace,
        constraintType: 'UNIQUE',
        tableName: 'users',
      ),
    );
  } else {
    SettingsErrorHandler.handleError(
      context,
      DatabaseException(
        'خطأ في قاعدة البيانات',
        userMessage: 'فشل إضافة المستخدم. يرجى المحاولة مرة أخرى.',
        originalError: e,
        stackTrace: stackTrace,
        operation: 'insert',
        tableName: 'users',
      ),
    );
  }
}
```

## ✅ Checklist

- [x] إنشاء SettingsErrorHandler
- [x] تحديث _createBackup
- [x] تحديث _showRestoreOptions
- [x] تحديث _restoreBackup
- [x] تحديث _editUser
- [x] تحديث _resetPassword
- [x] تحديث _deleteUser
- [x] تحديث _addNewUser
- [x] تحديث _saveSettings
- [ ] تحديث باقي الدوال

## 📚 المراجع

- [AppException Documentation](../../../../core/exceptions/app_exceptions.dart)
- [SECURITY_IMPROVEMENTS.md](../../../../SECURITY_IMPROVEMENTS.md)
