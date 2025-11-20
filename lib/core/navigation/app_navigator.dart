import 'package:flutter/material.dart';

/// Centralized navigator helper so we can trigger navigation without needing
/// a widget context that might get disposed mid-way (e.g., during logout).
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get _navigator => navigatorKey.currentState;

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
  ) async {
    return _navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    if (_navigator?.canPop() ?? false) {
      _navigator?.pop(result);
    }
  }
}
