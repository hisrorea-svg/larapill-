import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_spacing.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_card.dart';

/// قسم الإشعارات حسب التاريخ
class NotificationSection extends StatelessWidget {
  final String title;
  final List<NotificationEntity> notifications;

  const NotificationSection({
    super.key,
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: EdgeInsets.only(bottom: context.spacing12),
          child: Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: context.fontSize16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // قائمة الإشعارات
        ...notifications.map((notification) => NotificationCard(
              notification: notification,
            )),

        SizedBox(height: context.spacing20),
      ],
    );
  }
}
