import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_spacing.dart';

/// حالة الخطأ
class NotificationErrorWidget extends StatelessWidget {
  final String error;

  const NotificationErrorWidget({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          SizedBox(height: context.spacing24),
          Text(
            'خطأ في تحميل الإشعارات',
            style: GoogleFonts.tajawal(
              fontSize: context.fontSize18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: context.spacing8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing32),
            child: Text(
              error,
              style: GoogleFonts.tajawal(
                fontSize: context.fontSize14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
