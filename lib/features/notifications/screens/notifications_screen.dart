import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_spacing.dart';
import '../presentation/providers/notification_providers.dart';
import '../presentation/widgets/notification_header.dart';
import '../presentation/widgets/notification_section.dart';
import '../presentation/widgets/empty_notifications_widget.dart';
import '../presentation/widgets/notification_error_widget.dart';

/// شاشة الإشعارات الكاملة - Clean Architecture
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Header
            const NotificationHeader(),

            // Content
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, state) {
    // حالة التحميل
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // حالة الخطأ
    if (state.error != null) {
      return NotificationErrorWidget(error: state.error!);
    }

    // حالة فارغة
    if (state.notifications.isEmpty) {
      return const EmptyNotificationsWidget();
    }

    // عرض الإشعارات المجمعة
    final grouped = state.groupedNotifications;

    return ListView(
      padding: EdgeInsets.all(context.spacing20),
      children: [
        NotificationSection(
          title: 'اليوم',
          notifications: grouped['today'] ?? [],
        ),
        NotificationSection(
          title: 'أمس',
          notifications: grouped['yesterday'] ?? [],
        ),
        NotificationSection(
          title: 'سابقاً',
          notifications: grouped['older'] ?? [],
        ),
      ],
    );
  }
}
