import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../features/notifications/domain/entities/notification_entity.dart';
import '../../../features/notifications/domain/entities/notification_type.dart';
import '../../../features/notifications/domain/entities/notification_priority.dart';
import '../../../features/notifications/presentation/providers/notification_providers.dart';
import '../../../services/user_service.dart';
import '../../../core/services/session_timeout_service.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/navigation/notification_router.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../shared/widgets/session_status_widget.dart';
import 'package:pelaicons/pelaicons.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // زر البحث الشامل في المنتصف تماماً
            Expanded(
              flex: 3,
              child: Center(child: _GlobalSearchButton()),
            ),
            // العناصر الأخرى على الجهة اليمنى
            const SizedBox(width: 20),
            const SessionStatusWidget(showInAppBar: true),
            const SizedBox(width: 20),
            Container(
              height: 32,
              width: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 20),
            // تم دمج أيقونة الإشعارات داخل الشريط
            _UserInfoWidget(),
          ],
        ),
      ),
    );
  }
}

// 🔔 شريط الإشعارات المتحرك - يعرض الإشعارات واحداً تلو الآخر
// ✅ مربوط بـ StreamProvider للتحديثات اللحظية
// ✅ يدعم النقر للتوجيه للصفحة المناسبة
class _GlobalSearchButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GlobalSearchButton> createState() =>
      _GlobalSearchButtonState();
}

class _GlobalSearchButtonState extends ConsumerState<_GlobalSearchButton>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late final StreamSubscription<int> _tickerSubscription;

  @override
  void initState() {
    super.initState();
    // تبديل الإشعار كل 8 ثواني
    _tickerSubscription = Stream.periodic(
      const Duration(seconds: 8),
      (i) => i,
    ).listen((_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    });

    // أنيميشن نبض للأيقونة
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tickerSubscription.cancel(); // ✅ إلغاء الاشتراك
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام StreamProvider للتحديثات اللحظية
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: notificationsAsync.when(
          data: (allNotifications) {
            // فلترة الإشعارات غير المقروءة فقط
            final notifications =
                allNotifications.where((n) => !n.isRead).toList();

            if (notifications.isEmpty) {
              return Row(
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد إشعارات جديدة',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              );
            }

            // اختيار الإشعار الحالي بناءً على المؤشر
            final currentNotification =
                notifications[_currentIndex % notifications.length];

            return InkWell(
              onTap: () => _onNotificationTap(currentNotification),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // أيقونة نابضة
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Icon(
                          Icons.notifications_active,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 18,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  // نص الإشعار مع أنيميشن slide + fade
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        currentNotification.title,
                        key: ValueKey(currentNotification.id),
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // عداد الإشعارات غير المقروءة
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${notifications.length} جديد',
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // مؤشر التقدم
                  const SizedBox(width: 8),
                  Text(
                    '${(_currentIndex % notifications.length) + 1}/${notifications.length}',
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  // زر فتح قائمة الإشعارات
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showNotificationsPanel(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.list,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'جاري تحميل الإشعارات...',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'خطأ في تحميل الإشعارات',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عند النقر على الإشعار
  void _onNotificationTap(NotificationEntity notification) {
    // التنقل الذكي بناءً على نوع الإشعار
    NotificationRouter.navigate(context, notification);

    // تعليم الإشعار كمقروء إذا لم يكن كذلك
    if (!notification.isRead) {
      ref.read(markNotificationAsReadUseCaseProvider).call(notification.id);
    }
  }

  /// فتح قائمة الإشعارات المنسدلة
  void _showNotificationsPanel(BuildContext context, WidgetRef ref) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(
        maxWidth: 380,
        maxHeight: 500,
      ),
      items: [
        const PopupMenuItem(
          enabled: false,
          child: NotificationsDropdownContent(),
        ),
      ],
    );
  }
}

// 👤 User Info Widget - تصميم مدمج وأنيق
class _UserInfoWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userDisplayNameProvider);
    final userRole = ref.watch(userRoleProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                userRole,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Pelaicons.exitLightOutline,
                  size: 24, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                'تسجيل الخروج',
                style:
                    GoogleFonts.tajawal(fontSize: 13, color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          _showLogoutDialog(context, ref);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userRole,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final userName = ref.read(userDisplayNameProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.warning),
            const SizedBox(width: 12),
            Text('تسجيل الخروج',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تسجيل خروج $userName من النظام؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => _performLogout(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('تسجيل الخروج', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context, WidgetRef ref) async {
    // إغلاق حوار التأكيد
    Navigator.pop(context);

    // إظهار حوار التحميل
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'جاري تسجيل الخروج...',
                  style: GoogleFonts.tajawal(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      SessionTimeoutService.endSession(reason: 'manual_logout');
      await UserService.logout();

      // استخدام try-catch لتجنب خطأ ref disposed
      try {
        ref.invalidate(currentUserProvider);
        ref.invalidate(pharmacyInfoProvider);
        // ref.invalidate(notificationsStreamProvider); // Auto-disposed
      } catch (e) {
        // تجاهل الخطأ إذا كانت الـ widget قد تخلصت
      }

      // إغلاق حوار التحميل
      AppNavigator.pop();

      // تأخير بسيط لضمان انتهاء الأنيميشن
      await Future.delayed(const Duration(milliseconds: 100));

      if (context.mounted) {
        await AppNavigator.pushNamedAndRemoveUntil('/login');
      } else {
        // في حال فقدان الـ context، نستخدم المفتاح العام كحل أخير
        await AppNavigator.pushNamedAndRemoveUntil('/login');
      }
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الخروج: $e', name: 'Logout');
      AppNavigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// 📋 Notifications Dropdown - قائمة منسدلة أنيقة
class NotificationsDropdownContent extends ConsumerWidget {
  const NotificationsDropdownContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'الإشعارات',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Spacer(),
                Consumer(builder: (context, ref, child) {
                  final count = ref.watch(unreadCountProvider);
                  if (count == 0) return const SizedBox.shrink();

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Notifications List
          Flexible(
            child: ref.watch(notificationsStreamProvider).when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }
                    // عرض آخر 5 إشعارات فقط
                    final recentNotifications = notifications.take(5).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: recentNotifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(
                            context, recentNotifications[index], ref);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'خطأ في تحميل الإشعارات',
                            style: GoogleFonts.tajawal(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // فتح صفحة جميع الإشعارات
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: Text(
                      'عرض الكل',
                      style: GoogleFonts.tajawal(fontSize: 13),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(markAllNotificationsAsReadUseCaseProvider)
                          .call();
                      // لا حاجة لـ invalidate لأن Stream سيتحدث تلقائياً
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: Text(
                      'تعليم الكل كمقروء',
                      style: GoogleFonts.tajawal(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سيتم عرض الإشعارات الجديدة هنا',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationEntity notification, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // تعليم كمقروء
        if (!notification.isRead) {
          await ref
              .read(markNotificationAsReadUseCaseProvider)
              .call(notification.id);
        }

        // إغلاق القائمة
        if (context.mounted) {
          Navigator.pop(context);
        }

        // الانتقال للوجهة المطلوبة
        if (context.mounted) {
          NotificationRouter.navigate(context, notification);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getNotificationTypeColor(notification.type),
                    _getNotificationTypeColor(notification.type)
                        .withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _getNotificationTypeColor(notification.type)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  notification.type.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: notification.isRead
                                ? AppColors.textPrimary
                                : AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.inventory:
        return AppColors.warning;
      case NotificationType.sales:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.purchases:
        return AppColors.secondary;
      case NotificationType.user:
        return AppColors.primary;
      case NotificationType.reminder:
        return AppColors.warning;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// Bottom Sheet - الإصدار القديم (محتفظ به للمرجع)
class NotificationsBottomSheet extends ConsumerStatefulWidget {
  const NotificationsBottomSheet({super.key});

  @override
  ConsumerState<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState
    extends ConsumerState<NotificationsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header مع اسم المستخدم الحالي ✅
          _buildHeader(),

          // Notifications List للمستخدم الحالي ✅
          Expanded(
            child: ref.watch(notificationsStreamProvider).when(
                  data: (notifications) => notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(notifications),
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.notifications, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'الإشعارات',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // عرض اسم المستخدم الحالي ✅
          Text(
            '- ${ref.watch(userDisplayNameProvider)}',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),

          // عدد الإشعارات غير المقروءة للمستخدم الحالي ✅
          Consumer(builder: (context, ref, child) {
            final count = ref.watch(unreadCountProvider);
            if (count == 0) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count جديد',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),

          const SizedBox(width: 8),
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'تعيين الكل كمقروء',
              style:
                  GoogleFonts.tajawal(color: AppColors.primary, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationEntity> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationTile(notification);
      },
    );
  }

  Widget _buildNotificationTile(NotificationEntity notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationTypeColor(notification.type)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              notification.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.tajawal(
                  fontWeight:
                      notification.isRead ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(notification.priority)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPriorityColor(notification.priority)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                notification.priority.arabicName,
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: _getPriorityColor(notification.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getNotificationTypeColor(notification.type)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    notification.type.arabicName,
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: _getNotificationTypeColor(notification.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (!notification.isRead)
              PopupMenuItem(
                value: 'mark_read',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mark_email_read, size: 16),
                  title: Text('تعيين كمقروء',
                      style: GoogleFonts.tajawal(fontSize: 14)),
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.delete, size: 16, color: AppColors.error),
                title: Text(
                  'حذف',
                  style:
                      GoogleFonts.tajawal(fontSize: 14, color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد إشعارات',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'ستظهر الإشعارات الجديدة هنا عند حدوث أي نشاط مهم', // fixed text for simplicity
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الإشعارات...',
            style: GoogleFonts.tajawal(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('خطأ في تحميل الإشعارات', style: GoogleFonts.tajawal()),
          const SizedBox(height: 8),
          Text(error.toString(), style: GoogleFonts.tajawal(fontSize: 12)),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return const Color(0xFF2196F3);
      case NotificationType.inventory:
        return const Color(0xFFFF9800);
      case NotificationType.sales:
        return const Color(0xFF4CAF50);
      case NotificationType.purchases:
        return const Color(0xFF9C27B0);
      case NotificationType.user:
        return const Color(0xFF607D8B);
      case NotificationType.reminder:
        return const Color(0xFFFF5722);
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return const Color(0xFF4CAF50);
      case NotificationPriority.medium:
        return const Color(0xFF2196F3);
      case NotificationPriority.high:
        return const Color(0xFFFF9800);
      case NotificationPriority.urgent:
        return const Color(0xFFEF5350);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _markAsRead(NotificationEntity notification) async {
    if (!notification.isRead) {
      await ref
          .read(markNotificationAsReadUseCaseProvider)
          .call(notification.id);
    }
  }

  void _markAllAsRead() async {
    await ref.read(markAllNotificationsAsReadUseCaseProvider).call();
  }

  void _handleNotificationAction(
      String action, NotificationEntity notification) async {
    switch (action) {
      case 'mark_read':
        await ref
            .read(markNotificationAsReadUseCaseProvider)
            .call(notification.id);
        break;
      case 'delete':
        final repository = ref.read(notificationRepositoryProvider);
        await repository.delete(notification.id);
        break;
    }
  }

  // _generateSampleNotifications removed
}
