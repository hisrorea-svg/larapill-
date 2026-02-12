import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/presentation/screens/financial_hub_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/controllers/session_controller.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../purchases/presentation/screens/purchases_dashboard_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../pos/presentation/screens/pos_screen.dart';
import '../../../returns/presentation/screens/returns_screen.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/top_bar.dart';
import '../../../../core/widgets/session_warning_dialog.dart';
import 'dashboard_screen.dart';
import '../../../debts/presentation/screens/debts_screen.dart';
import 'dart:developer' as developer;

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    _setFullScreen();
    // NOTE: Realtime sync service removed. Use SyncNotifier from features/sync.
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    developer.log('🔴 MainLayout build - selectedIndex: $selectedIndex',
        name: 'MainLayout');

    // ✅ مراقبة حالة الجلسة
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.warning && next.remainingTime != null) {
        _showSessionWarning(context, next.remainingTime!);
      } else if (next.status == SessionStatus.expired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⏰ انتهت مهلة الجلسة. تم تسجيل الخروج تلقائياً',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return GestureDetector(
      // ✅ تحديث النشاط عبر الـ Controller
      onTap: () =>
          ref.read(sessionControllerProvider.notifier).updateActivity(),
      onPanDown: (_) =>
          ref.read(sessionControllerProvider.notifier).updateActivity(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // شريط علوي موحد بلون واحد
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // جزء Sidebar - اللوجو والاسم
                    Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.medication,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) => Text(
                                ref.watch(pharmacyDisplayNameProvider),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // جزء TopBar - البحث والإشعارات والمستخدم
                    const Expanded(child: TopBar()),
                  ],
                ),
              ),
              // المحتوى الرئيسي
              Expanded(
                child: Row(
                  children: [
                    const SidebarMenu(),
                    Expanded(
                      child: _getSelectedScreen(selectedIndex),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionWarning(BuildContext context, Duration remaining) {
    developer.log('عرض تحذير انتهاء الجلسة - باقي ${remaining.inMinutes} دقيقة',
        name: 'MainLayout');

    if (remaining.inMinutes <= 1) {
      SessionWarningHelper.showWarning(
        context,
        remainingTime: remaining,
        onExtendSession: () =>
            ref.read(sessionControllerProvider.notifier).extendSession(),
        onLogout: () => ref.read(sessionControllerProvider.notifier).logout(),
      );
    } else if (remaining.inMinutes <= 5) {
      SessionWarningHelper.showSimpleWarning(
        context,
        remainingTime: remaining,
        onExtendSession: () =>
            ref.read(sessionControllerProvider.notifier).extendSession(),
      );
    }
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const PosScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const PurchasesDashboardScreen();
      case 4:
        return const ReturnsScreen();
      case 5:
        return const DebtsScreen();
      case 6:
        return const FinancialHubScreen();
      case 7:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
