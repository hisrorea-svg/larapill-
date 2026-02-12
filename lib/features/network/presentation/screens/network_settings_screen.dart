/// lib/features/network/presentation/screens/network_settings_screen.dart
///
/// DEPRECATED: This screen is replaced by SyncSetupScreen.
///
/// This file is kept for backward compatibility but redirects to SyncSetupScreen.
/// Use features/sync/presentation/screens/sync_setup_screen.dart instead.
library;

import 'package:flutter/material.dart';
import '../../../sync/presentation/screens/sync_setup_screen.dart';

/// شاشة إعدادات الشبكة - موجهة لشاشة المزامنة الجديدة
class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncSetupScreen();
  }
}
