import 'dart:async';
import 'dart:developer' as developer;
import '../storage/hive_storage.dart';

/// 🕐 خدمة إدارة انتهاء الجلسات المحسنة
/// تتميز بـ:
/// - إعدادات قابلة للتخصيص
/// - حفظ حالة الجلسة عند إغلاق التطبيق
/// - تحذيرات متعددة المستويات
/// - إحصائيات الجلسات
/// - حماية من فقدان البيانات
class SessionTimeoutService {
  // إعدادات افتراضية قابلة للتخصيص
  static Duration _sessionTimeout = const Duration(hours: 8);
  static Duration _warningTime = const Duration(minutes: 5);
  static Duration _idleCheckInterval = const Duration(minutes: 1);

  // حالة الجلسة
  static Timer? _sessionTimer;
  static Timer? _warningTimer;
  static Timer? _idleCheckTimer;
  static DateTime? _sessionStartTime;
  static DateTime? _lastActivity;
  static bool _isWarningShown = false;
  static String? _currentUserId;

  // Callbacks
  static Function()? _onTimeout;
  static Function(Duration remaining)? _onWarning;
  static Function(Duration remaining)? _onIdleCheck;
  static Function()? _onSessionExtended;

  // إحصائيات الجلسة
  static int _totalSessions = 0;
  static Duration _totalActiveTime = Duration.zero;
  static List<Map<String, dynamic>> _sessionHistory = [];

  /// بدء جلسة جديدة مع إعدادات مخصصة
  static Future<void> startSession({
    required String userId,
    required Function() onTimeout,
    Function(Duration remaining)? onWarning,
    Function(Duration remaining)? onIdleCheck,
    Function()? onSessionExtended,
    Duration? customTimeout,
    Duration? customWarningTime,
  }) async {
    // إنهاء الجلسة السابقة إن وجدت
    await endSession();

    // تحديث الإعدادات
    if (customTimeout != null) _sessionTimeout = customTimeout;
    if (customWarningTime != null) _warningTime = customWarningTime;

    // تهيئة الجلسة الجديدة
    _currentUserId = userId;
    _onTimeout = onTimeout;
    _onWarning = onWarning;
    _onIdleCheck = onIdleCheck;
    _onSessionExtended = onSessionExtended;
    _sessionStartTime = DateTime.now();
    _lastActivity = DateTime.now();
    _isWarningShown = false;

    // بدء المؤقتات
    _resetTimers();
    _startIdleMonitoring();

    // حفظ معلومات الجلسة
    await _saveSessionData();

    // تحديث الإحصائيات
    _totalSessions++;

    developer.log(
        '🕐 بدء جلسة جديدة - المستخدم: $userId, المهلة: ${_formatDuration(_sessionTimeout)}',
        name: 'SessionTimeout');
  }

  /// تحديث نشاط المستخدم
  static Future<void> updateActivity({String? activityType}) async {
    if (!isSessionActive()) return;

    _lastActivity = DateTime.now();
    _isWarningShown = false;
    _resetTimers();

    // حفظ النشاط
    await _saveSessionData();

    // تسجيل النشاط في وضع التطوير
    if (activityType != null) {
      developer.log('👆 نشاط المستخدم: $activityType', name: 'SessionTimeout');
    }
  }

  /// إنهاء الجلسة وحفظ الإحصائيات
  static Future<void> endSession({String? reason}) async {
    if (_sessionStartTime != null && _lastActivity != null) {
      final sessionDuration = _lastActivity!.difference(_sessionStartTime!);
      _totalActiveTime += sessionDuration;

      // إضافة للتاريخ
      _sessionHistory.add({
        'userId': _currentUserId,
        'startTime': _sessionStartTime!.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'duration': sessionDuration.inMinutes,
        'reason': reason ?? 'normal_logout',
      });

      // الاحتفاظ بآخر 50 جلسة فقط
      if (_sessionHistory.length > 50) {
        _sessionHistory.removeAt(0);
      }
    }

    // إلغاء المؤقتات
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _idleCheckTimer?.cancel();

    // مسح البيانات
    _sessionTimer = null;
    _warningTimer = null;
    _idleCheckTimer = null;
    _sessionStartTime = null;
    _lastActivity = null;
    _currentUserId = null;
    _isWarningShown = false;

    // حفظ الإحصائيات
    await _saveStatistics();

    developer.log('🛑 انتهت الجلسة - السبب: ${reason ?? "عادي"}',
        name: 'SessionTimeout');
  }

  /// تمديد الجلسة الحالية
  static Future<void> extendSession({Duration? additionalTime}) async {
    if (!isSessionActive()) return;

    final extension = additionalTime ?? _sessionTimeout;
    _lastActivity = DateTime.now().add(extension);
    _isWarningShown = false;

    _resetTimers();
    await _saveSessionData();

    _onSessionExtended?.call();

    developer.log('⏰ تم تمديد الجلسة بـ ${_formatDuration(extension)}',
        name: 'SessionTimeout');
  }

  /// إعادة تعيين المؤقتات
  static void _resetTimers() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();

    if (!isSessionActive()) return;

    final remaining = getRemainingTime();
    if (remaining == null || remaining <= Duration.zero) return;

    // مؤقت التحذير
    if (remaining > _warningTime && !_isWarningShown) {
      final warningDelay = remaining - _warningTime;
      _warningTimer = Timer(warningDelay, () {
        if (isSessionActive() && !_isWarningShown) {
          _isWarningShown = true;
          final remainingTime = getRemainingTime();
          if (remainingTime != null) {
            _onWarning?.call(remainingTime);
            developer.log(
                '⚠️ تحذير انتهاء الجلسة - باقي ${_formatDuration(remainingTime)}',
                name: 'SessionTimeout');
          }
        }
      });
    }

    // مؤقت انتهاء الجلسة
    _sessionTimer = Timer(remaining, () async {
      developer.log('⏰ انتهت مهلة الجلسة', name: 'SessionTimeout');
      await endSession(reason: 'timeout');
      _onTimeout?.call();
    });
  }

  /// بدء مراقبة الخمول
  static void _startIdleMonitoring() {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = Timer.periodic(_idleCheckInterval, (timer) {
      if (!isSessionActive()) {
        timer.cancel();
        return;
      }

      final remaining = getRemainingTime();
      if (remaining != null) {
        _onIdleCheck?.call(remaining);

        // تحذير إضافي عند الدقيقة الأخيرة
        if (remaining <= const Duration(minutes: 1) && !_isWarningShown) {
          _isWarningShown = true;
          _onWarning?.call(remaining);
        }
      }
    });
  }

  /// الحصول على الوقت المتبقي للجلسة
  static Duration? getRemainingTime() {
    if (_lastActivity == null) return null;

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _sessionTimeout - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// فحص إذا كانت الجلسة نشطة
  static bool isSessionActive() {
    final remaining = getRemainingTime();
    return remaining != null && remaining > Duration.zero;
  }

  /// الحصول على معلومات الجلسة الحالية
  static Map<String, dynamic> getSessionInfo() {
    return {
      'isActive': isSessionActive(),
      'userId': _currentUserId,
      'startTime': _sessionStartTime?.toIso8601String(),
      'lastActivity': _lastActivity?.toIso8601String(),
      'remainingTime': getRemainingTime()?.inMinutes,
      'sessionDuration': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inMinutes
          : null,
      'warningShown': _isWarningShown,
    };
  }

  /// الحصول على إحصائيات الجلسات
  static Future<Map<String, dynamic>> getSessionStatistics() async {
    _loadStatistics();

    return {
      'totalSessions': _totalSessions,
      'totalActiveTime': _totalActiveTime.inHours,
      'averageSessionTime': _totalSessions > 0
          ? (_totalActiveTime.inMinutes / _totalSessions).round()
          : 0,
      'recentSessions': _sessionHistory.take(10).toList(),
      'currentSession': getSessionInfo(),
    };
  }

  /// تغيير إعدادات الجلسة
  static Future<void> updateSettings({
    Duration? sessionTimeout,
    Duration? warningTime,
    Duration? idleCheckInterval,
  }) async {
    if (sessionTimeout != null) {
      _sessionTimeout = sessionTimeout;
      developer.log('⚙️ تحديث مهلة الجلسة: ${_formatDuration(sessionTimeout)}');
    }

    if (warningTime != null) {
      _warningTime = warningTime;
      developer.log('⚙️ تحديث وقت التحذير: ${_formatDuration(warningTime)}');
    }

    if (idleCheckInterval != null) {
      _idleCheckInterval = idleCheckInterval;
      developer.log(
          '⚙️ تحديث فترة فحص الخمول: ${_formatDuration(idleCheckInterval)}');
    }

    // إعادة تعيين المؤقتات بالإعدادات الجديدة
    if (isSessionActive()) {
      _resetTimers();
      _startIdleMonitoring();
    }

    await _saveSessionData();
  }

  /// استعادة الجلسة بعد إعادة تشغيل التطبيق
  static Future<bool> restoreSession({
    required String userId,
    required Function() onTimeout,
    Function(Duration remaining)? onWarning,
  }) async {
    try {
      final sessionData = HiveStorage.getSecure<String>('active_session');

      if (sessionData == null) return false;

      final data = Map<String, dynamic>.from(Uri.splitQueryString(sessionData));

      final storedUserId = data['userId'];
      final lastActivityStr = data['lastActivity'];

      if (storedUserId != userId || lastActivityStr == null) {
        await _clearSessionData();
        return false;
      }

      final lastActivity = DateTime.parse(lastActivityStr);
      final elapsed = DateTime.now().difference(lastActivity);

      if (elapsed >= _sessionTimeout) {
        await _clearSessionData();
        return false;
      }

      // استعادة الجلسة
      _currentUserId = userId;
      _onTimeout = onTimeout;
      _onWarning = onWarning;
      _lastActivity = lastActivity;
      _sessionStartTime =
          DateTime.parse(data['startTime'] ?? DateTime.now().toIso8601String());

      _resetTimers();
      _startIdleMonitoring();

      developer.log('🔄 تم استعادة الجلسة بنجاح للمستخدم: $userId',
          name: 'SessionTimeout');

      return true;
    } catch (e) {
      developer.log('❌ فشل في استعادة الجلسة: $e', name: 'SessionTimeout');
      await _clearSessionData();
      return false;
    }
  }

  /// حفظ بيانات الجلسة
  static Future<void> _saveSessionData() async {
    if (!isSessionActive()) return;

    try {
      final sessionData = {
        'userId': _currentUserId ?? '',
        'startTime': _sessionStartTime?.toIso8601String() ?? '',
        'lastActivity': _lastActivity?.toIso8601String() ?? '',
        'timeout': _sessionTimeout.inMilliseconds.toString(),
      };

      final queryString = Uri(queryParameters: sessionData).query;
      await HiveStorage.setSecure('active_session', queryString);
    } catch (e) {
      developer.log('❌ فشل في حفظ بيانات الجلسة: $e', name: 'SessionTimeout');
    }
  }

  /// مسح بيانات الجلسة
  static Future<void> _clearSessionData() async {
    try {
      await HiveStorage.removeSecure('active_session');
    } catch (e) {
      developer.log('❌ فشل في مسح بيانات الجلسة: $e', name: 'SessionTimeout');
    }
  }

  /// حفظ الإحصائيات
  static Future<void> _saveStatistics() async {
    try {
      await HiveStorage.setSecure('total_sessions', _totalSessions);
      await HiveStorage.setSecure(
          'total_active_time', _totalActiveTime.inMinutes);

      final historyJson = _sessionHistory
          .map((session) => Uri(
              queryParameters:
                  session.map((k, v) => MapEntry(k, v.toString()))).query)
          .toList();

      await HiveStorage.setSecure('session_history', historyJson);
    } catch (e) {
      developer.log('❌ فشل في حفظ الإحصائيات: $e', name: 'SessionTimeout');
    }
  }

  /// تحميل الإحصائيات
  static void _loadStatistics() {
    try {
      _totalSessions = HiveStorage.getSecure<int>('total_sessions') ?? 0;
      final activeTimeMinutes =
          HiveStorage.getSecure<int>('total_active_time') ?? 0;
      _totalActiveTime = Duration(minutes: activeTimeMinutes);

      final historyList = HiveStorage.getSecure<List>('session_history') ?? [];
      _sessionHistory = historyList.map((sessionStr) {
        final params = Uri.splitQueryString(sessionStr.toString());
        return {
          'userId': params['userId'] ?? '',
          'startTime': params['startTime'] ?? '',
          'endTime': params['endTime'] ?? '',
          'duration': int.tryParse(params['duration'] ?? '0') ?? 0,
          'reason': params['reason'] ?? 'unknown',
        };
      }).toList();
    } catch (e) {
      developer.log('❌ فشل في تحميل الإحصائيات: $e', name: 'SessionTimeout');
    }
  }

  /// تنسيق المدة للعرض
  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} يوم و ${duration.inHours.remainder(24)} ساعة';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ساعة و ${duration.inMinutes.remainder(60)} دقيقة';
    } else {
      return '${duration.inMinutes} دقيقة';
    }
  }

  /// تنسيق الوقت المتبقي للعرض
  static String formatRemainingTime() {
    final remaining = getRemainingTime();
    if (remaining == null || remaining <= Duration.zero) {
      return 'انتهت الجلسة';
    }
    return 'باقي ${_formatDuration(remaining)}';
  }

  /// إعادة تعيين جميع الإحصائيات (للصيانة)
  static Future<void> resetAllStatistics() async {
    _totalSessions = 0;
    _totalActiveTime = Duration.zero;
    _sessionHistory.clear();

    await _saveStatistics();
    await _clearSessionData();

    developer.log('🗑️ تم إعادة تعيين جميع إحصائيات الجلسات',
        name: 'SessionTimeout');
  }
}
