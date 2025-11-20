import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/inventory/screens/inventory_screen.dart';
import '../features/purchases/screens/purchases_screen.dart';
import '../features/returns/screens/returns_screen.dart';
import '../features/settings/screens/settings_screen.dart';

// مزود لتتبع الصفحة المحددة
final selectedIndexProvider = StateProvider<int>((ref) => 0);

// مزود لعرض الشاشة المناسبة
final mainContentProvider = Provider<Widget>((ref) {
  final selectedIndex = ref.watch(selectedIndexProvider);

  switch (selectedIndex) {
    case 0:
      return const DashboardScreen();
    case 1:
      return const PosScreen();
    case 2:
      return const InventoryScreen();
    case 3:
      return const PurchasesScreen();
    case 4:
      return const ReturnsScreen();
    case 5:
      return const SettingsScreen();
    default:
      return const DashboardScreen();
  }
});
