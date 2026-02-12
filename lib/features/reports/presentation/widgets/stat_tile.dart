import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// بلاطة إحصائية واحدة
class StatTile extends StatelessWidget {
  /// العنوان
  final String label;

  /// القيمة
  final String value;

  /// الأيقونة (اختياري)
  final IconData? icon;

  /// اللون (اختياري)
  final Color? color;

  /// حجم الخط للقيمة
  final double valueFontSize;

  /// هل القيمة مهمة (للتنبيهات)
  final bool isAlert;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.valueFontSize = 20,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // العنوان مع الأيقونة
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // القيمة
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            if (isAlert) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: displayColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// صف من الإحصائيات
class StatRow extends StatelessWidget {
  final List<StatTile> stats;
  final double spacing;

  const StatRow({
    super.key,
    required this.stats,
    this.spacing = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: 16,
      children: stats,
    );
  }
}
