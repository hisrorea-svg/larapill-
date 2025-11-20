import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../services/session_timeout_service.dart';
import '../../services/user_service.dart';
import '../navigation/app_navigator.dart';
import '../../features/shared/widgets/session_warning_dialog.dart';

// ✅ حالة الجلسة
enum SessionStatus { active, warning, expired }

class SessionState {
  final SessionStatus status;
  final Duration? remainingTime;

  const SessionState({this.status = SessionStatus.active, this.remainingTime});
}

// ✅ Provider
final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

class SessionController extends StateNotifier<SessionState>
    with WidgetsBindingObserver {
  SessionController() : super(const SessionState()) {
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionTimeoutService.endSession(reason: 'controller_disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        SessionTimeoutService.updateActivity(activityType: 'app_resumed');
        developer.log('التطبيق عاد للمقدمة - تحديث النشاط',
            name: 'SessionController');
        break;
      case AppLifecycleState.paused:
        developer.log('التطبيق في الخلفية', name: 'SessionController');
        break;
      case AppLifecycleState.detached:
        SessionTimeoutService.endSession(reason: 'app_detached');
        break;
      default:
        break;
    }
  }

  Future<void> _initializeSession() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) return;

      final restored = await SessionTimeoutService.restoreSession(
        userId: currentUser.id,
        onTimeout: _handleTimeout,
        onWarning: _handleWarning,
      );

      if (!restored) {
        await SessionTimeoutService.startSession(
          userId: currentUser.id,
          onTimeout: _handleTimeout,
          onWarning: _handleWarning,
          onIdleCheck: _handleIdleCheck,
          onSessionExtended: _handleSessionExtended,
          customTimeout: const Duration(hours: 8),
          customWarningTime: const Duration(minutes: 5),
        );
      }
      developer.log('تم تهيئة جلسة العمل بنجاح', name: 'SessionController');
    } catch (e) {
      developer.log('خطأ في تهيئة الجلسة: $e', name: 'SessionController');
    }
  }

  void _handleTimeout() {
    state = const SessionState(status: SessionStatus.expired);
    logout(reason: 'timeout');
  }

  void _handleWarning(Duration remaining) {
    state = SessionState(status: SessionStatus.warning, remainingTime: remaining);
  }

  void _handleIdleCheck(Duration remaining) {
    // يمكن إضافة منطق إضافي هنا
  }

  void _handleSessionExtended() {
    state = const SessionState(status: SessionStatus.active);
  }

  Future<void> extendSession() async {
    try {
      await SessionTimeoutService.extendSession(
        additionalTime: const Duration(hours: 2),
      );
      developer.log('تم تمديد الجلسة', name: 'SessionController');
    } catch (e) {
      developer.log('خطأ في تمديد الجلسة: $e', name: 'SessionController');
    }
  }

  Future<void> logout({String reason = 'manual_logout'}) async {
    developer.log('تسجيل خروج: $reason', name: 'SessionController');
    SessionTimeoutService.endSession(reason: reason);
    await UserService.logout();
    await AppNavigator.pushNamedAndRemoveUntil('/login');
  }

  void updateActivity() {
    SessionTimeoutService.updateActivity(activityType: 'user_interaction');
  }
}
