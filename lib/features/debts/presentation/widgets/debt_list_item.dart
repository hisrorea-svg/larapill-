import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer_debt.dart';
import '../../domain/entities/debt_status.dart';

class DebtListItem extends StatelessWidget {
  final CustomerDebt debt;
  final VoidCallback onPaymentTap;
  final VoidCallback onRefresh;

  const DebtListItem({
    super.key,
    required this.debt,
    required this.onPaymentTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Background (Very Subtle)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Right Side: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              debt.customerName.isNotEmpty
                                  ? debt.customerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              debt.customerName,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),

                      // Status
                      Row(
                        children: [
                          Icon(_statusIcon, size: 14, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusText,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Separator
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

                // Left Side: Amount & Action
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${debt.remainingDebt.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'د.ع',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onPaymentTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'تسجيل دفعة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (debt.status) {
      case DebtStatus.overdue:
        return AppColors.error;
      case DebtStatus.warning:
        return AppColors.warning;
      case DebtStatus.normal:
        return AppColors.success;
    }
  }

  IconData get _statusIcon {
    switch (debt.status) {
      case DebtStatus.overdue:
        return Icons.warning_rounded;
      case DebtStatus.warning:
        return Icons.access_time_filled;
      case DebtStatus.normal:
        return Icons.check_circle;
    }
  }

  String get _statusText {
    switch (debt.status) {
      case DebtStatus.overdue:
        return 'متأخر ${debt.debtAgeDays} يوم';
      case DebtStatus.warning:
        return 'قريب التأخير';
      case DebtStatus.normal:
        return 'منذ ${debt.debtAgeDays} يوم';
    }
  }
}
