import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/return_entity.dart';
import '../providers/returns_providers.dart';
import '../widgets/return_form_dialog.dart';
import '../widgets/return_details_dialog.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  @override
  void initState() {
    super.initState();
    // تحديث البيانات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(returnsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredReturnsAsync = ref.watch(filteredReturnsProvider);
    final currentPage = ref.watch(currentReturnPageProvider);
    final totalPages = ref.watch(totalReturnPagesProvider);
    final totalCount = ref.watch(totalReturnsCountProvider);
    final paginatedReturns = ref.watch(paginatedReturnsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_return,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة المرتجعات',
                        style: GoogleFonts.tajawal(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'معالجة وتتبع المرتجعات',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showReturnFormDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'مرتجع جديد',
                      style: GoogleFonts.tajawal(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== Filters =====
              _buildFiltersBar(ref),
              const SizedBox(height: 20),

              // ===== Table =====
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: filteredReturnsAsync.when(
                    data: (allReturns) {
                      if (allReturns.isEmpty) {
                        return _buildEmptyState(context, ref);
                      }
                      return Column(
                        children: [
                          // الجدول
                          Expanded(
                            child: _buildReturnsTable(
                                context, ref, paginatedReturns),
                          ),
                          // التنقل بين الصفحات
                          const SizedBox(height: 12),
                          if (totalPages > 1)
                            _buildPaginationControls(
                                ref, currentPage, totalPages, totalCount),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text(
                        'خطأ في تحميل المرتجعات\n$err',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Filters Bar =====
  Widget _buildFiltersBar(WidgetRef ref) {
    final searchQuery = ref.watch(returnSearchQueryProvider);
    final statusFilter = ref.watch(returnStatusFilterProvider);

    return Row(
      children: [
        // البحث
        Expanded(
          child: TextField(
            onChanged: (value) {
              ref.read(returnSearchQueryProvider.notifier).state = value;
              ref.read(currentReturnPageProvider.notifier).state = 0;
            },
            decoration: InputDecoration(
              hintText: 'ابحث برقم المرتجع أو رقم الفاتورة...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // فلتر الحالة
        DropdownButton<ReturnStatus?>(
          value: statusFilter,
          onChanged: (value) {
            ref.read(returnStatusFilterProvider.notifier).state = value;
            ref.read(currentReturnPageProvider.notifier).state = 0;
          },
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('جميع الحالات', style: GoogleFonts.tajawal()),
            ),
            ...ReturnStatus.values.map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status.arabicName, style: GoogleFonts.tajawal()),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // زر تنظيف الفلاتر
        if (searchQuery.isNotEmpty || statusFilter != null)
          IconButton(
            onPressed: () {
              ref.read(returnSearchQueryProvider.notifier).state = '';
              ref.read(returnStatusFilterProvider.notifier).state = null;
              ref.read(currentReturnPageProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.close),
            tooltip: 'مسح الفلاتر',
          ),
      ],
    );
  }

  // ===== Empty State =====
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_return_outlined,
              size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'لا توجد مرتجعات',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة مرتجع جديد',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showReturnFormDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('مرتجع جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== DataTable2 محسّن =====
  Widget _buildReturnsTable(
    BuildContext context,
    WidgetRef ref,
    List<Return> paginatedReturns,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final hasEnoughSpace = screenWidth >= 900;

        return DataTable2(
          headingRowHeight: 48,
          dataRowHeight: 45,
          columnSpacing: 8,
          horizontalMargin: 8,
          minWidth: hasEnoughSpace ? 900 : null,
          fixedTopRows: 1,
          border: TableBorder(
            horizontalInside: const BorderSide(color: Colors.black, width: 1.0),
            verticalInside: const BorderSide(color: Colors.black, width: 1.0),
            top: const BorderSide(color: Colors.black, width: 1.2),
            bottom: const BorderSide(color: Colors.black, width: 1.2),
            left: const BorderSide(color: Colors.black, width: 1.2),
            right: const BorderSide(color: Colors.black, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          columns: [
            DataColumn2(
              label: Center(
                child: Text('ت',
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 30 : 25,
              numeric: true,
            ),
            DataColumn2(
              label: Center(
                child: Text('رقم المرتجع',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 180 : 140,
            ),
            DataColumn2(
              label: Center(
                child: Text('التاريخ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 130 : 100,
            ),
            DataColumn2(
              label: Center(
                child: Text('السبب',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 150 : 120,
            ),
            DataColumn2(
              label: Center(
                child: Text('الحالة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 120 : 100,
            ),
            DataColumn2(
              label: Center(
                child: Text('المبلغ المسترد',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 130 : 110,
              numeric: true,
            ),
            DataColumn2(
              label: Center(
                child: Text('الإجراءات',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              fixedWidth: hasEnoughSpace ? 140 : 120,
            ),
          ],
          rows: paginatedReturns.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final return_ = entry.value;

            final statusColor = _getStatusColor(return_.status);

            return DataRow2(
              color: WidgetStatePropertyAll(
                return_.status == ReturnStatus.rejected
                    ? AppColors.error.withValues(alpha: 0.08)
                    : return_.status == ReturnStatus.completed
                        ? AppColors.success.withValues(alpha: 0.08)
                        : Colors.transparent,
              ),
              cells: [
                DataCell(
                  Center(
                    child: Text(index.toString(),
                        style: GoogleFonts.tajawal(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(return_.id,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(return_.returnDate.toString().split(' ')[0],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(fontSize: 13)),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(return_.reason.arabicName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(fontSize: 13)),
                  ),
                ),
                DataCell(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        return_.status.arabicName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text('${return_.totalRefund.toStringAsFixed(0)} د.ع',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(fontSize: 13)),
                  ),
                ),
                DataCell(
                  Center(
                    child: _buildActions(context, ref, return_),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // ===== Pagination Controls =====
  Widget _buildPaginationControls(
    WidgetRef ref,
    int currentPage,
    int totalPages,
    int totalItems,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'إجمالي: $totalItems مرتجع (50 في كل صفحة)',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () =>
                        ref.read(currentReturnPageProvider.notifier).state = 0
                    : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'الأولى',
              ),
              IconButton(
                onPressed: currentPage > 0
                    ? () => ref.read(currentReturnPageProvider.notifier).state--
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'السابق',
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'صفحة ${currentPage + 1} من $totalPages',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => ref.read(currentReturnPageProvider.notifier).state++
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'التالي',
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => ref.read(currentReturnPageProvider.notifier).state =
                        totalPages - 1
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'الأخيرة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Actions =====
  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    Return return_,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'التفاصيل',
          onPressed: () => _showReturnDetailsDialog(context, return_),
          icon: const Icon(Icons.visibility, color: AppColors.info, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 18,
        ),
        const SizedBox(width: 4),
        if (return_.status == ReturnStatus.pending)
          IconButton(
            tooltip: 'موافقة',
            onPressed: () => _updateReturnStatus(
                context, ref, return_.id, ReturnStatus.approved),
            icon: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 18,
          ),
      ],
    );
  }

  // ===== Helpers =====
  Color _getStatusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return AppColors.warning;
      case ReturnStatus.approved:
        return AppColors.info;
      case ReturnStatus.completed:
        return AppColors.success;
      case ReturnStatus.rejected:
        return AppColors.error;
    }
  }

  void _showReturnFormDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ReturnFormDialog(
        onReturnCreated: () {
          ref.invalidate(filteredReturnsProvider);
          ref.read(currentReturnPageProvider.notifier).state = 0;
        },
      ),
    );
  }

  void _showReturnDetailsDialog(BuildContext context, Return return_) {
    showDialog(
      context: context,
      builder: (_) => ReturnDetailsDialog(return_: return_),
    );
  }

  Future<void> _updateReturnStatus(
    BuildContext context,
    WidgetRef ref,
    String returnId,
    ReturnStatus newStatus,
  ) async {
    final service = ref.read(returnServiceProvider);
    final success = await service.updateReturnStatus(returnId, newStatus);

    if (success) {
      ref.invalidate(filteredReturnsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة المرتجع بنجاح',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحديث المرتجع',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
