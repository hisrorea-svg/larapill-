import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer_debt.dart';
import '../../domain/entities/debts_stats.dart';
import '../../domain/entities/debt_status.dart';
import '../providers/debts_providers.dart';
import '../widgets/debt_list_item.dart';
import '../widgets/payment_dialog.dart';

/// شاشة إدارة الديون - PROFESSIONAL DESIGN
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(debtActionsProvider).refresh();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final pagination = ref.read(debtPaginationProvider);
      if (!pagination.isLoadingMore && pagination.hasMore) {
        ref.read(debtActionsProvider).loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(currentDebtsProvider);
    final pagination = ref.watch(debtPaginationProvider);
    final statsAsync = ref.watch(debtsStatsProvider);

    ref.watch(debouncedSearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title + Search + Filters in ONE ROW
              _buildHeader(),
              const SizedBox(height: 16),

              // Statistics Cards - COMPACT
              _buildStatsCards(statsAsync),
              const SizedBox(height: 16),

              // Debts Grid - RESPONSIVE with Pagination
              Expanded(
                child: _buildDebtsGrid(debts, pagination),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // العنوان والأيقونة - اليمين
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إدارة الديون',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Tajawal',
                        ),
                  ),
                  const Text(
                    'متابعة ديون العملاء وتسجيل الدفعات',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          // البحث والفلاتر - المنتصف
          Expanded(
            child: _buildCompactSearchAndFilters(),
          ),

          const SizedBox(width: 16),

          // زر التحديث - اليسار
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'تحديث',
            onPressed: () => ref.read(debtActionsProvider).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSearchAndFilters() {
    return Consumer(
      builder: (context, ref, child) {
        final filter = ref.watch(debtFilterProvider);
        final countsAsync = ref.watch(debtCountsByStatusProvider);

        return countsAsync.when(
          data: (counts) {
            final total = counts.values.fold(0, (a, b) => a + b);

            return Row(
              children: [
                // البحث - أعرض وresponsive
                Expanded(
                  flex: 3,
                  child: _buildEnhancedSearchBar(),
                ),

                const SizedBox(width: 12),

                // الفلاتر
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCompactFilterChip(
                          label: 'الكل',
                          count: total,
                          isSelected: filter.statusFilter == null,
                          color: AppColors.primary,
                          onTap: () => ref
                              .read(debtActionsProvider)
                              .setStatusFilter(null),
                        ),
                        const SizedBox(width: 6),
                        _buildCompactFilterChip(
                          label: 'متأخرة',
                          count: counts[DebtStatus.overdue] ?? 0,
                          isSelected: filter.statusFilter == DebtStatus.overdue,
                          color: AppColors.error,
                          onTap: () => ref
                              .read(debtActionsProvider)
                              .setStatusFilter(DebtStatus.overdue),
                        ),
                        const SizedBox(width: 6),
                        _buildCompactFilterChip(
                          label: 'قريبة',
                          count: counts[DebtStatus.warning] ?? 0,
                          isSelected: filter.statusFilter == DebtStatus.warning,
                          color: AppColors.warning,
                          onTap: () => ref
                              .read(debtActionsProvider)
                              .setStatusFilter(DebtStatus.warning),
                        ),
                        const SizedBox(width: 6),
                        _buildCompactFilterChip(
                          label: 'عادية',
                          count: counts[DebtStatus.normal] ?? 0,
                          isSelected: filter.statusFilter == DebtStatus.normal,
                          color: AppColors.success,
                          onTap: () => ref
                              .read(debtActionsProvider)
                              .setStatusFilter(DebtStatus.normal),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // الترتيب
                _buildCompactSortDropdown(filter.sortType),
              ],
            );
          },
          loading: () => const SizedBox(height: 36),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildEnhancedSearchBar() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: 'بحث عن عميل...',
        hintStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          color: Colors.grey.shade500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.search, size: 18, color: AppColors.primary),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear,
                    size: 16, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  ref.read(debtActionsProvider).setSearchQuery('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
      onChanged: (value) {
        setState(() {});
        ref.read(debtActionsProvider).setSearchQuery(value);
      },
    );
  }

  Widget _buildCompactFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSortDropdown(DebtSortType currentSort) {
    return PopupMenuButton<DebtSortType>(
      initialValue: currentSort,
      onSelected: (value) => ref.read(debtActionsProvider).setSortType(value),
      itemBuilder: (context) => [
        _buildSortItem(DebtSortType.newest, 'الأحدث أولاً',
            Icons.arrow_downward, currentSort),
        _buildSortItem(DebtSortType.oldest, 'الأقدم أولاً', Icons.arrow_upward,
            currentSort),
        _buildSortItem(DebtSortType.highestAmount, 'الأكبر مبلغاً',
            Icons.trending_up, currentSort),
        _buildSortItem(DebtSortType.lowestAmount, 'الأصغر مبلغاً',
            Icons.trending_down, currentSort),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              _getSortLabel(currentSort),
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<DebtSortType> _buildSortItem(
    DebtSortType value,
    String label,
    IconData icon,
    DebtSortType current,
  ) {
    final isSelected = value == current;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  String _getSortLabel(DebtSortType type) {
    switch (type) {
      case DebtSortType.newest:
        return 'الأحدث';
      case DebtSortType.oldest:
        return 'الأقدم';
      case DebtSortType.highestAmount:
        return 'الأكبر';
      case DebtSortType.lowestAmount:
        return 'الأصغر';
    }
  }

  Widget _buildStatsCards(AsyncValue<DebtsStats> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildCompactStat(
                'إجمالي الديون',
                '${_formatAmount(stats.totalDebts)} د.ع',
                Icons.money_off,
                const Color(0xFFE74C3C),
              ),
              _buildDivider(),
              _buildCompactStat(
                'ديون متأخرة',
                '${_formatAmount(stats.overdueDebts)} د.ع',
                Icons.warning_amber_rounded,
                const Color(0xFFE67E22),
                subtitle: '${stats.overdueCount} عميل',
                isAlert: stats.overdueCount > 0,
              ),
              _buildDivider(),
              _buildCompactStat(
                'المدينين',
                stats.debtorsCount.toString(),
                Icons.people,
                const Color(0xFF3498DB),
              ),
              _buildDivider(),
              _buildCompactStat(
                'المحصّل الشهر',
                '${_formatAmount(stats.collectedThisMonth)} د.ع',
                Icons.trending_up,
                const Color(0xFF2ECC71),
                subtitle: '${stats.paymentsThisMonth} دفعة',
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDivider() =>
      Container(height: 40, width: 1, color: Colors.grey.shade200);

  Widget _buildCompactStat(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAlert) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsGrid(
      List<CustomerDebt> debts, DebtPaginationState pagination) {
    if (debts.isEmpty && !pagination.isLoadingMore) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1400
            ? 5
            : width > 1200
                ? 4
                : width > 800
                    ? 3
                    : width > 500
                        ? 2
                        : 1;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.1,
                ),
                itemCount: debts.length,
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return DebtListItem(
                    debt: debt,
                    onPaymentTap: () => _showPaymentDialog(debt),
                    onRefresh: () => ref.read(debtActionsProvider).refresh(),
                  );
                },
              ),
            ),
            if (pagination.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (!pagination.hasMore && debts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا توجد المزيد من النتائج',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final filter = ref.watch(debtFilterProvider);
    final hasFilter =
        filter.searchQuery.isNotEmpty || filter.statusFilter != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.check_circle_outline,
            size: 64,
            color: hasFilter
                ? AppColors.textSecondary.withValues(alpha: 0.3)
                : AppColors.success.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'لا توجد نتائج للبحث' : 'لا توجد ديون',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
            ),
          ),
          if (hasFilter)
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(debtActionsProvider).setSearchQuery('');
                ref.read(debtActionsProvider).setStatusFilter(null);
              },
              child: const Text(
                'إزالة الفلاتر',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(CustomerDebt debt) {
    showDialog(
      context: context,
      builder: (context) => DebtPaymentDialog(
        debt: debt,
        onPaymentComplete: () {
          ref.read(debtActionsProvider).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم تسجيل الدفعة بنجاح ✓',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toInt().toString();
  }
}
