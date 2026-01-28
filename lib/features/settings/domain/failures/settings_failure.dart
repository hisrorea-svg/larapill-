/// Failures for Settings feature
///
/// Sealed class hierarchy for typed error handling
/// Pure Dart - no Flutter dependencies
sealed class SettingsFailure {
  final String message;
  final String? code;

  const SettingsFailure(this.message, [this.code]);

  @override
  String toString() => 'SettingsFailure($code): $message';
}

/// Database operation failure
class DatabaseSettingsFailure extends SettingsFailure {
  const DatabaseSettingsFailure([String message = 'فشل في قاعدة البيانات'])
      : super(message, 'DATABASE_ERROR');
}

/// Validation failure
class ValidationSettingsFailure extends SettingsFailure {
  final Map<String, String> fieldErrors;

  const ValidationSettingsFailure(
    String message, {
    this.fieldErrors = const {},
  }) : super(message, 'VALIDATION_ERROR');
}

/// User not found failure
class UserNotFoundFailure extends SettingsFailure {
  const UserNotFoundFailure([String message = 'المستخدم غير موجود'])
      : super(message, 'USER_NOT_FOUND');
}

/// Username already exists failure
class UsernameExistsFailure extends SettingsFailure {
  const UsernameExistsFailure([String message = 'اسم المستخدم موجود مسبقاً'])
      : super(message, 'USERNAME_EXISTS');
}

/// Authentication failure
class AuthenticationFailure extends SettingsFailure {
  const AuthenticationFailure([String message = 'فشل في المصادقة'])
      : super(message, 'AUTH_FAILURE');
}

/// Permission denied failure
class PermissionDeniedFailure extends SettingsFailure {
  const PermissionDeniedFailure([String message = 'ليس لديك الصلاحية'])
      : super(message, 'PERMISSION_DENIED');
}

/// Settings not found failure
class SettingsNotFoundFailure extends SettingsFailure {
  const SettingsNotFoundFailure([String message = 'الإعدادات غير موجودة'])
      : super(message, 'SETTINGS_NOT_FOUND');
}

/// Invalid password failure
class InvalidPasswordFailure extends SettingsFailure {
  const InvalidPasswordFailure([String message = 'كلمة المرور غير صحيحة'])
      : super(message, 'INVALID_PASSWORD');
}

/// Weak password failure
class WeakPasswordFailure extends SettingsFailure {
  const WeakPasswordFailure([String message = 'كلمة المرور ضعيفة'])
      : super(message, 'WEAK_PASSWORD');
}

/// Cache failure
class CacheSettingsFailure extends SettingsFailure {
  const CacheSettingsFailure([String message = 'فشل في التخزين المؤقت'])
      : super(message, 'CACHE_ERROR');
}

/// Unknown failure
class UnknownSettingsFailure extends SettingsFailure {
  const UnknownSettingsFailure([String message = 'خطأ غير متوقع'])
      : super(message, 'UNKNOWN_ERROR');
}
