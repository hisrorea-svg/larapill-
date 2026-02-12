import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../reports/presentation/screens/financial_hub_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../purchases/presentation/screens/purchases_dashboard_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../pos/presentation/screens/pos_screen.dart';
import '../../../returns/presentation/screens/returns_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../debts/presentation/screens/debts_screen.dart';
import '../../../tools/presentation/screens/tools_screen.dart';
import '../../../../core/controllers/session_controller.dart';

import '../../../../core/widgets/session_warning_dialog.dart';
import '../../../dashboard/presentation/widgets/top_bar.dart';
import '../widgets/terminal_type_selector.dart';
import 'dart:developer' as developer;

/// صفحة القائمة الرئيسية - تصميم نظيف ومبسط
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  // ✅ قائمة الأيقونات للـ Pre-caching
  static const _iconPaths = [
    'assets/Icons/home.svg',
    'assets/Icons/pos.svg',
    'assets/Icons/inventory.svg',
    'assets/Icons/purchases.svg',
    'assets/Icons/Returns.svg',
    'assets/Icons/Debts.svg',
    'assets/Icons/reports.svg',
    'assets/Icons/settings.svg',
    'assets/Icons/tool.svg',
  ];

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _precacheIcons();
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

  /// ✅ Pre-caching للأيقونات لتحسين الأداء
  /// 
  /// ملاحظة: flutter_svg يقوم بالـ caching تلقائياً بعد أول render.
  /// هذا الكود يضمن تحميل الأيقونات في الذاكرة بمجرد فتح القائمة.
  void _precacheIcons() async {
    // تحميل ملفات SVG في الذاكرة (ليس render، فقط قراءة الملفات)
    for (final path in _iconPaths) {
      try {
        await DefaultAssetBundle.of(context).loadString(path);
      } catch (e) {
        developer.log('⚠️ Failed to preload icon $path: $e', name: 'MenuScreen');
      }
    }
    developer.log('✅ Pre-loaded ${_iconPaths.length} icons', name: 'MenuScreen');
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
                // زر تسجيل الخروج
                _buildLogoutButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: [
          // Logo + اسم الصيدلية (على اليسار)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الشعار مع خلفية بيضاء
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // اسم الصيدلية
              Consumer(
                builder: (context, ref, _) => Text(
                  ref.watch(pharmacyDisplayNameProvider),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Terminal Type Selector - نوع الكاشير
          const TerminalTypeSelector(),

          const SizedBox(width: 16),

          // اسم المستخدم + أيقونة (على اليمين)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(userDisplayNameProvider);
                    return Text(
                      currentUser,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      const _MenuItem(
        svgPath: 'assets/Icons/home.svg',
        title: 'لوحة التحكم',
        color: Colors.blue,
        screen: DashboardScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/pos.svg',
        title: 'نقطة البيع',
        color: Colors.green,
        screen: PosScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/inventory.svg',
        title: 'المخزون',
        color: Colors.orange,
        screen: InventoryScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/purchases.svg',
        title: 'المشتريات',
        color: Colors.purple,
        screen: PurchasesDashboardScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/Returns.svg',
        title: 'المرتجعات',
        color: Colors.teal,
        screen: ReturnsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/Debts.svg',
        title: 'الديون',
        color: Colors.red,
        screen: DebtsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/reports.svg',
        title: 'التقارير',
        color: Colors.indigo,
        screen: FinancialHubScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/settings.svg',
        title: 'الإعدادات',
        color: Colors.grey,
        screen: SettingsScreen(),
      ),
      const _MenuItem(
        svgPath: 'assets/Icons/tool.svg',
        title: 'الأدوات',
        color: Colors.cyan,
        screen: ToolsScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب عدد الأعمدة بناءً على عرض الشاشة
        int crossAxisCount;
        double maxCardWidth;

        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
          maxCardWidth = 140;
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
          maxCardWidth = 140;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
          maxCardWidth = 120;
        } else {
          crossAxisCount = 2;
          maxCardWidth = 110;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (maxCardWidth + 16) * crossAxisCount + 48,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _MinimalMenuTile(
                    svgPath: item.svgPath,
                    title: item.title,
                    color: item.color,
                    onTap: () => _navigateToScreen(item.screen, item.title),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
      icon: const Icon(
        Icons.logout,
        color: AppColors.secondary,
        size: 20,
      ),
      label: const Text(
        'تسجيل الخروج',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
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
          // Fade + Scale من المنتصف
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
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
  final Color color;
  final Widget screen;

  const _MenuItem({
    required this.svgPath,
    required this.title,
    required this.color,
    required this.screen,
  });
}

/// بطاقة قائمة مبسطة - تصميم نظيف مع ألوان
class _MinimalMenuTile extends StatefulWidget {
  final String svgPath;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MinimalMenuTile({
    required this.svgPath,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MinimalMenuTile> createState() => _MinimalMenuTileState();
}

class _MinimalMenuTileState extends State<_MinimalMenuTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        Future.microtask(() {
          if (mounted) setState(() => _isHovered = true);
        });
      },
      onExit: (_) {
        Future.microtask(() {
          if (mounted) setState(() => _isHovered = false);
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.6)
                    : AppColors.border.withValues(alpha: 0.6),
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 🎨 أيقونة خلفية كبيرة شفافة (زخرفة)
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 0.12 : 0.06,
                    child: SvgPicture.asset(
                      widget.svgPath,
                      width: 80,
                      height: 80,
                      colorFilter: ColorFilter.mode(
                        widget.color,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                // المحتوى الرئيسي
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الأيقونة داخل مربع ملون
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? widget.color.withValues(alpha: 0.15)
                              : widget.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            widget.svgPath,
                            width: 28,
                            height: 28,
                            colorFilter: ColorFilter.mode(
                              widget.color,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // العنوان
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
                          const Text(
                            'القائمة الرئيسية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
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
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
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
      onEnter: (_) {
        Future.microtask(() {
          if (mounted) setState(() => _isHovered = true);
        });
      },
      onExit: (_) {
        Future.microtask(() {
          if (mounted) setState(() => _isHovered = false);
        });
      },
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
