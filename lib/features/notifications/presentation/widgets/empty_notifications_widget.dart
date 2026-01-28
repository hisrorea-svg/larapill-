import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_spacing.dart';

/// حالة فارغة - لا توجد إشعارات
class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: context.spacing24),
          Text(
            'لا توجد إشعارات',
            style: GoogleFonts.tajawal(
              fontSize: context.fontSize20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing8),
          Text(
            'ستظهر الإشعارات الجديدة هنا',
            style: GoogleFonts.tajawal(
              fontSize: context.fontSize14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
