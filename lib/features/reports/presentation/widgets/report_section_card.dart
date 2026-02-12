import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// كارت قسم تقرير موحد
class ReportSectionCard extends StatefulWidget {
  /// عنوان القسم
  final String title;

  /// الأيقونة
  final IconData icon;

  /// اللون الرئيسي
  final Color color;

  /// المحتوى الرئيسي
  final Widget content;

  /// المحتوى الثانوي (اختياري)
  final Widget? secondaryContent;

  /// عند الضغط على "عرض الكل" (اختياري)
  final VoidCallback? onViewAll;

  /// هل يُظهر حالة التحميل
  final bool isLoading;

  /// هل يوجد خطأ
  final bool hasError;

  /// رسالة الخطأ
  final String? errorMessage;

  const ReportSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.secondaryContent,
    this.onViewAll,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<ReportSectionCard> createState() => _ReportSectionCardState();
}

class _ReportSectionCardState extends State<ReportSectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.3)
                : AppColors.border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.08)
                  : AppColors.cardShadow,
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر
            _buildHeader(),
            const SizedBox(height: 16),
            // الفاصل
            Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            // المحتوى
            if (widget.isLoading)
              _buildLoading()
            else if (widget.hasError)
              _buildError()
            else
              widget.content,
            // المحتوى الثانوي
            if (widget.secondaryContent != null &&
                !widget.isLoading &&
                !widget.hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.secondaryContent!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // الأيقونة
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // العنوان
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // زر عرض الكل
        if (widget.onViewAll != null)
          TextButton.icon(
            onPressed: widget.onViewAll,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text(
              'عرض الكل',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: widget.color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage ?? 'حدث خطأ في تحميل البيانات',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
