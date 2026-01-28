import '../entities/pharmacy_settings_entity.dart';
import '../entities/notification_settings_entity.dart';
import '../failures/settings_failure.dart';

/// Either type for functional error handling
/// Left = Failure, Right = Success value
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isRight;

  const Either.left(L value)
      : _left = value,
        _right = null,
        _isRight = false;

  const Either.right(R value)
      : _left = null,
        _right = value,
        _isRight = true;

  bool get isLeft => !_isRight;
  bool get isRight => _isRight;

  L get left {
    if (_isRight) throw StateError('Cannot get left from Right');
    return _left as L;
  }

  R get right {
    if (!_isRight) throw StateError('Cannot get right from Left');
    return _right as R;
  }

  /// Fold the Either into a single value
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    return _isRight ? onRight(_right as R) : onLeft(_left as L);
  }

  /// Map the right value
  Either<L, T> map<T>(T Function(R) mapper) {
    return _isRight
        ? Either.right(mapper(_right as R))
        : Either.left(_left as L);
  }

  /// Get right value or default
  R getOrElse(R defaultValue) => _isRight ? _right as R : defaultValue;
}

/// Unit type for void operations
class Unit {
  const Unit._();
  static const Unit unit = Unit._();
}

/// واجهة Repository لإدارة الإعدادات
///
/// هذا الـ interface يستخدم Either للتعامل مع الأخطاء بطريقة typed
/// يجب أن يتم تنفيذه في data layer
abstract class SettingsRepository {
  // ==================== Pharmacy Settings ====================

  /// جلب إعدادات الصيدلية
  Future<Either<SettingsFailure, PharmacySettingsEntity?>>
      getPharmacySettings();

  /// حفظ أو تحديث إعدادات الصيدلية
  Future<Either<SettingsFailure, PharmacySettingsEntity>> savePharmacySettings(
    PharmacySettingsEntity settings,
  );

  // ==================== Notification Settings ====================

  /// جلب إعدادات الإشعارات
  Future<Either<SettingsFailure, NotificationSettingsEntity>>
      getNotificationSettings();

  /// حفظ إعدادات الإشعارات
  Future<Either<SettingsFailure, NotificationSettingsEntity>>
      saveNotificationSettings(
    NotificationSettingsEntity settings,
  );

  // ==================== System Settings ====================

  /// جلب إعداد نظامي بواسطة المفتاح
  Future<Either<SettingsFailure, String?>> getSystemSetting(String key,
      {String? defaultValue});

  /// حفظ إعداد نظامي
  Future<Either<SettingsFailure, Unit>> setSystemSetting(
    String key,
    String value, {
    String? description,
    String? category,
  });
}
