/// Failures for Auth feature
///
/// Sealed class hierarchy for typed error handling
/// Pure Dart - no Flutter dependencies
sealed class AuthFailure {
  final String message;
  final String? code;

  const AuthFailure(this.message, [this.code]);

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// Invalid credentials (wrong password)
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    String message = 'كلمة المرور غير صحيحة',
  ]) : super(message, 'INVALID_CREDENTIALS');
}

/// User not found
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    String message = 'المستخدم غير موجود',
  ]) : super(message, 'USER_NOT_FOUND');
}

/// Account locked (too many failed attempts)
class AccountLockedFailure extends AuthFailure {
  final Duration? lockDuration;
  final int? remainingMinutes;

  const AccountLockedFailure({
    String message = 'الحساب مقفل مؤقتاً',
    this.lockDuration,
    this.remainingMinutes,
  }) : super(message, 'ACCOUNT_LOCKED');

  String get lockMessage {
    if (remainingMinutes != null && remainingMinutes! > 0) {
      return 'الحساب مقفل. حاول مرة أخرى بعد $remainingMinutes دقيقة';
    }
    return message;
  }
}

/// Account disabled by admin
class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure([
    String message = 'الحساب معطل. تواصل مع المسؤول',
  ]) : super(message, 'ACCOUNT_DISABLED');
}

/// Session expired
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure([
    String message = 'انتهت صلاحية الجلسة. سجل دخولك مجدداً',
  ]) : super(message, 'SESSION_EXPIRED');
}

/// Network/connection failure
class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    String message = 'فشل الاتصال بالخادم',
  ]) : super(message, 'NETWORK_ERROR');
}

/// Database failure
class DatabaseFailure extends AuthFailure {
  const DatabaseFailure([
    String message = 'خطأ في قاعدة البيانات',
  ]) : super(message, 'DATABASE_ERROR');
}

/// Password change required
class ForcePasswordChangeFailure extends AuthFailure {
  const ForcePasswordChangeFailure([
    String message = 'يجب تغيير كلمة المرور',
  ]) : super(message, 'FORCE_PASSWORD_CHANGE');
}

/// Weak password (for password change)
class WeakPasswordFailure extends AuthFailure {
  final List<String> requirements;

  const WeakPasswordFailure({
    String message = 'كلمة المرور ضعيفة',
    this.requirements = const [],
  }) : super(message, 'WEAK_PASSWORD');
}

/// Unknown/unexpected failure
class UnknownFailure extends AuthFailure {
  const UnknownFailure([
    String message = 'حدث خطأ غير متوقع',
  ]) : super(message, 'UNKNOWN_ERROR');
}
