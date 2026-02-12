import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class FinancialKPICard extends StatelessWidget {
  final String title;
  final num value;
  final IconData icon;
  final Color color;
  final String? trend;
  final String? trendValue;
  final bool isCurrency;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onTap;

  const FinancialKPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendValue,
    this.isCurrency = false,
    this.isLoading = false,
    this.isError = false,
    this.onTap,
  });

  const FinancialKPICard.loading({super.key})
      : title = '',
        value = 0,
        icon = Icons.abc,
        color = Colors.grey,
        trend = null,
        trendValue = null,
        isCurrency = false,
        isLoading = true,
        isError = false,
        onTap = null;

  const FinancialKPICard.error({super.key})
      : title = 'خطأ في التحميل',
        value = 0,
        icon = Icons.error_outline,
        color = Colors.red,
        trend = null,
        trendValue = null,
        isCurrency = false,
        isLoading = false,
        isError = true,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    if (isError) {
      return _buildError();
    }

    final formattedValue = isCurrency
        ? NumberFormat.currency(
                symbol: 'د.ع', decimalDigits: 0, locale: 'ar_IQ')
            .format(value)
        : NumberFormat('#,###', 'ar_IQ').format(value);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (trend != null && trendValue != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            trendValue!,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedValue,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            SizedBox(height: 8),
            Text(
              'تعذر تحميل البيانات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
