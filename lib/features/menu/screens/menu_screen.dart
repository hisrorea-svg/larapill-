import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../widgets/menu_tile.dart';
import '../widgets/terminal_type_selector.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../purchases/screens/daily_purchase_requests_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../pos/screens/pos_screen.dart';
import '../../returns/screens/returns_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../debts/screens/debts_screen.dart';
import '../../reports/screens/modern_reports_screen.dart';
import '../../../core/controllers/session_controller.dart';
import '../../../core/services/realtime_sync_service.dart';
import '../../shared/widgets/session_warning_dialog.dart';
import '../../dashboard/widgets/top_bar.dart';
import 'dart:developer' as developer;

/// صفحة القائمة الرئيسية - تعرض الخيارات كمربعات شبكية
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    _setFullScreen();
    // بدء خدمة المزامنة التلقائية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeSyncServiceProvider).start();
    });
  }

  @override
  void dispose() {
    ref.read(realtimeSyncServiceProvider).stop();
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
    // مراقبة حالة الجلسة
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
      onTap: () =>
          ref.read(sessionControllerProvider.notifier).updateActivity(),
      onPanDown: (_) =>
          ref.read(sessionControllerProvider.notifier).updateActivity(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Grid
                Expanded(
                  child: _buildMenuGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          // Logo + اسم الصيدلية
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) => Text(
                ref.watch(pharmacyDisplayNameProvider),
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Terminal Type Selector
          const TerminalTypeSelector(),
          const SizedBox(width: 16),

          // تسجيل الخروج
          IconButton(
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            icon: Icon(
              Icons.logout,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      const _MenuItem(
        svgPath: 'assets/Icons/home.svg',
        title: 'الرئيسية',
        subtitle: 'لوحة التحكم',
        color: Colors.blue,
        screen: DashboardScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/pos.svg',
        title: 'نقطة البيع',
        subtitle: 'POS',
        color: Colors.green,
        screen: PosScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/inventory.svg',
        title: 'المخزون',
        subtitle: 'إدارة المنتجات',
        color: Colors.orange,
        screen: InventoryScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/purchases.svg',
        title: 'المشتريات',
        subtitle: 'الطلبيات اليومية',
        color: Colors.purple,
        screen: DailyPurchaseRequestsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/Returns.svg',
        title: 'المرتجعات',
        subtitle: 'إدارة الإرجاع',
        color: Colors.teal,
        screen: ReturnsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/Debts.svg',
        title: 'الديون',
        subtitle: 'إدارة الائتمان',
        color: Colors.red,
        screen: DebtsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/reports.svg',
        title: 'التقارير',
        subtitle: 'الإحصائيات',
        color: Colors.indigo,
        screen: ModernReportsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/settings.svg',
        title: 'الإعدادات',
        subtitle: 'تخصيص النظام',
        color: Colors.grey,
        screen: SettingsScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب عدد الأعمدة بناءً على عرض الشاشة
        int crossAxisCount;
        double childAspectRatio;
        double horizontalPadding;

        if (constraints.maxWidth >= 1600) {
          crossAxisCount = 6;
          childAspectRatio = 1.1;
          horizontalPadding = 60;
        } else if (constraints.maxWidth >= 1350) {
          crossAxisCount = 5;
          childAspectRatio = 1.1;
          horizontalPadding = 50;
        } else if (constraints.maxWidth >= 1000) {
          crossAxisCount = 4;
          childAspectRatio = 1.0;
          horizontalPadding = 40;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 3;
          childAspectRatio = 0.95;
          horizontalPadding = 30;
        } else if (constraints.maxWidth >= 500) {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
          horizontalPadding = 20;
        } else {
          crossAxisCount = 2;
          childAspectRatio =
              1.1; // قللنا النسبة قليلاً لتجنب الـ overflow في الشاشات الصغيرة جداً
          horizontalPadding = 16;
        }

        return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return MenuTile(
                svgPath: item.svgPath,
                title: item.title,
                subtitle: item.subtitle,
                color: item.color,
                onTap: () => _navigateToScreen(item.screen, item.title),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToScreen(Widget screen, String title) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _ScreenWrapper(
          title: title,
          child: screen,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showSessionWarning(BuildContext context, Duration remaining) {
    developer.log('عرض تحذير انتهاء الجلسة - باقي ${remaining.inMinutes} دقيقة',
        name: 'MenuScreen');

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
}

/// عنصر قائمة
class _MenuItem {
  final String svgPath;
  final String title;
  final String? subtitle;
  final Color color;
  final Widget screen;
  const _MenuItem({
    required this.svgPath,
    required this.title,
    this.subtitle,
    required this.color,
    required this.screen,
  });
}

/// غلاف الشاشة مع الهيدر الكامل وزر رجوع
class _ScreenWrapper extends ConsumerWidget {
  final String title;
  final Widget child;

  const _ScreenWrapper({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
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
              // Header الكامل مع زر رجوع
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
                    // Logo section مع زر رجوع
                    Container(
                      width: 350,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // زر الرجوع للقائمة مع تأثيرات
                          _AnimatedMenuButton(
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          // نص القائمة الرئيسية
                          Text(
                            'القائمة الرئيسية',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // فاصل
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 12),
                          // عنوان الصفحة
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // TopBar الأصلي (البحث، الإشعارات، المستخدم)
                    const Expanded(child: TopBar()),
                  ],
                ),
              ),
              // محتوى الصفحة
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر القائمة مع تأثيرات hover وانيميشن
class _AnimatedMenuButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedMenuButton({required this.onTap});

  @override
  State<_AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<_AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? Colors.white.withValues(alpha: 0.35)
                      : _isHovered
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isHovered
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isHovered ? 0.05 : 0,
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: _isHovered ? 24 : 22,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
