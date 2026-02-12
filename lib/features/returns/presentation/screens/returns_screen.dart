import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/return_entity.dart';
import '../providers/returns_providers.dart';
import '../widgets/return_form_dialog.dart';
import '../widgets/return_details_dialog.dart';
import '../../data/repositories/returns_repository.dart';

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  @override
  void initState() {
    super.initState();
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
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildFiltersBar(ref),
              const SizedBox(height: 20),
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
                          Expanded(
                            child: _buildReturnsTable(
                                context, ref, paginatedReturns),
                          ),
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
                        style: const TextStyle(
                            fontFamily: 'Tajawal', color: AppColors.error),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_return,
              color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة المرتجعات',
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            Text('معالجة وتتبع المرتجعات',
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showReturnFormDialog(context, ref),
          icon: const Icon(Icons.add),
          label:
              const Text('مرتجع جديد', style: TextStyle(fontFamily: 'Tajawal')),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(WidgetRef ref) {
    final searchQuery = ref.watch(returnSearchQueryProvider);
    final statusFilter = ref.watch(returnStatusFilterProvider);

    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              ref.read(returnSearchQueryProvider.notifier).state = value;
              ref.read(currentReturnPageProvider.notifier).state = 0;
            },
            decoration: InputDecoration(
              hintText: 'ابحث برقم المرتجع أو رقم الفاتورة...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<ReturnStatus?>(
          value: statusFilter,
          onChanged: (value) {
            ref.read(returnStatusFilterProvider.notifier).state = value;
            ref.read(currentReturnPageProvider.notifier).state = 0;
          },
          items: [
            const DropdownMenuItem(
                value: null,
                child: Text('جميع الحالات',
                    style: TextStyle(fontFamily: 'Tajawal'))),
            ...ReturnStatus.values.map(
              (status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.arabicName,
                      style: const TextStyle(fontFamily: 'Tajawal'))),
            ),
          ],
        ),
        if (searchQuery.isNotEmpty || statusFilter != null)
          IconButton(
            onPressed: () {
              ref.read(returnSearchQueryProvider.notifier).state = '';
              ref.read(returnStatusFilterProvider.notifier).state = null;
              ref.read(currentReturnPageProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_return_outlined,
              size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('لا توجد مرتجعات',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showReturnFormDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('مرتجع جديد'),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsTable(
      BuildContext context, WidgetRef ref, List<Return> paginatedReturns) {
    return DataTable2(
      columns: const [
        DataColumn2(label: Center(child: Text('ت')), fixedWidth: 40),
        DataColumn2(
            label: Center(child: Text('رقم المرتجع')), size: ColumnSize.L),
        DataColumn2(label: Center(child: Text('التاريخ')), size: ColumnSize.M),
        DataColumn2(label: Center(child: Text('السبب')), size: ColumnSize.M),
        DataColumn2(label: Center(child: Text('الحالة')), size: ColumnSize.M),
        DataColumn2(
            label: Center(child: Text('المبلغ')),
            size: ColumnSize.M,
            numeric: true),
        DataColumn2(
            label: Center(child: Text('الإجراءات')), size: ColumnSize.S),
      ],
      rows: paginatedReturns.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final ret = entry.value;
        return DataRow2(cells: [
          DataCell(Center(child: Text(index.toString()))),
          DataCell(Center(child: Text(ret.id))),
          DataCell(
              Center(child: Text(ret.returnDate.toString().split(' ')[0]))),
          DataCell(Center(child: Text(ret.reason.arabicName))),
          DataCell(Center(child: _buildStatusBadge(ret.status))),
          DataCell(Center(child: Text(ret.totalRefund.toStringAsFixed(0)))),
          DataCell(Center(child: _buildActions(context, ref, ret))),
        ]);
      }).toList(),
    );
  }

  Widget _buildStatusBadge(ReturnStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status.arabicName,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Return ret) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            icon: const Icon(Icons.visibility, color: AppColors.info),
            onPressed: () => _showReturnDetailsDialog(context, ret)),
        if (ret.status == ReturnStatus.pending)
          IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              onPressed: () => _updateReturnStatus(
                  context, ref, ret.id, ReturnStatus.approved)),
      ],
    );
  }

  Widget _buildPaginationControls(
      WidgetRef ref, int page, int total, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('إجمالي: $count مرتجع'),
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: page > 0
                    ? () => ref.read(currentReturnPageProvider.notifier).state--
                    : null),
            Text('صفحة ${page + 1} من $total'),
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: page < total - 1
                    ? () => ref.read(currentReturnPageProvider.notifier).state++
                    : null),
          ],
        ),
      ],
    );
  }

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
        onReturnCreated: () => ref.invalidate(filteredReturnsProvider),
      ),
    );
  }

  void _showReturnDetailsDialog(BuildContext context, Return ret) {
    showDialog(
      context: context,
      builder: (_) => ReturnDetailsDialog(return_: ret),
    );
  }

  Future<void> _updateReturnStatus(BuildContext context, WidgetRef ref,
      String id, ReturnStatus status) async {
    try {
      await ref.read(returnsRepositoryProvider).updateStatus(id, status);
      ref.invalidate(filteredReturnsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم التحديث بنجاح'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
