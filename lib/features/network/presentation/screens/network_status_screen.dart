/// lib/features/network/presentation/screens/network_status_screen.dart
///
/// DEPRECATED: This screen is replaced by SyncStatusScreen.
///
/// This file redirects to SyncStatusScreen from features/sync.
library;

import 'package:flutter/material.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';

/// شاشة حالة الشبكة - موجهة لشاشة حالة المزامنة الجديدة
class NetworkStatusScreen extends StatelessWidget {
  const NetworkStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncStatusScreen();
  }
}
