import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/reports_providers.dart';
import '../widgets/financial_kpi_card.dart';
import '../widgets/debts_overview_table.dart';
import '../widgets/top_expenses_table.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/recent_transactions_log.dart';
import '../widgets/period_selector.dart';
import '../../domain/entities/report_period.dart';

class FinancialHubScreen extends ConsumerStatefulWidget {
  const FinancialHubScreen({super.key});

  @override
  ConsumerState<FinancialHubScreen> createState() => _FinancialHubScreenState();
}

class _FinancialHubScreenState extends ConsumerState<FinancialHubScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedPeriodType = ref.watch(selectedPeriodTypeProvider);

    return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: () async => refreshAllReports(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                PeriodSelector(
                  selectedPeriod: selectedPeriodType,
                  onPeriodChanged: (type) {
                    ref.read(selectedPeriodTypeProvider.notifier).state = type;
                  },
                  onCustomDateTap: () => _showCustomDatePicker(context),
                ),
                const SizedBox(height: 24),
                _buildKPILayer(),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1200) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildMainColumn()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildSideColumn()),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMainColumn(),
                          const SizedBox(height: 24),
                          _buildSideColumn(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ignore: prefer_const_constructors
            gradient: LinearGradient(
              colors: const [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics_outlined,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المركز المالي',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'ar').format(DateTime.now()),
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildActionButton(
          icon: Icons.print_outlined,
          label: 'طباعة التقرير',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle:
            const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKPILayer() {
    final financialReport = ref.watch(financialReportProvider);
    final debtsReport = ref.watch(debtsReportProvider);

    return Row(
      children: [
        Expanded(
          child: financialReport.when(
            data: (data) => FinancialKPICard(
              title: 'صافي الرصيد',
              value: data.netProfit,
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
              isCurrency: true,
            ),
            loading: () => const FinancialKPICard.loading(),
            error: (_, __) => const FinancialKPICard.error(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: debtsReport.when(
            data: (data) => FinancialKPICard(
              title: 'إجمالي الديون',
              value: data.totalDebts,
              icon: Icons.money_off_csred_outlined,
              color: AppColors.error,
              trend: 'ديون مستحقة قريباً',
              trendValue: '${data.debtorsCount} عميل',
              isCurrency: true,
            ),
            loading: () => const FinancialKPICard.loading(),
            error: (_, __) => const FinancialKPICard.error(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: debtsReport.when(
            data: (data) => FinancialKPICard(
              title: 'العملاء النشطون',
              value: data.debtorsCount,
              icon: Icons.people_outline,
              color: AppColors.info,
              trend: 'عملاء لديهم ديون',
              trendValue: '${data.overdueCount} متأخر',
              isCurrency: false,
            ),
            loading: () => const FinancialKPICard.loading(),
            error: (_, __) => const FinancialKPICard.error(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: financialReport.when(
            data: (data) => FinancialKPICard(
              title: 'المصروفات الشهرية',
              value: data.totalExpenses,
              icon: Icons.trending_down,
              color: AppColors.warning,
              isCurrency: true,
            ),
            loading: () => const FinancialKPICard.loading(),
            error: (_, __) => const FinancialKPICard.error(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainColumn() {
    return const Column(
      children: [
        DebtsOverviewTable(),
        SizedBox(height: 24),
        RecentTransactionsLog(),
      ],
    );
  }

  Widget _buildSideColumn() {
    return const Column(
      children: [
        TopExpensesTable(),
        SizedBox(height: 24),
        QuickActionsPanel(),
      ],
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    DateTime? startDate = ref.read(customStartDateProvider);
    DateTime? endDate = ref.read(customEndDateProvider);

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => _CustomDateRangePicker(
        initialStartDate: startDate,
        initialEndDate: endDate,
      ),
    );

    if (result != null && result['start'] != null && result['end'] != null) {
      ref.read(customStartDateProvider.notifier).state = result['start'];
      ref.read(customEndDateProvider.notifier).state = result['end'];
      ref.read(selectedPeriodTypeProvider.notifier).state =
          ReportPeriodType.custom;
    }
  }
}

class _CustomDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _CustomDateRangePicker({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    startDate = widget.initialStartDate ?? DateTime.now();
    endDate = widget.initialEndDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'اختر الفترة الزمنية',
        style: TextStyle(fontFamily: 'Tajawal'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('تاريخ البداية',
                style: TextStyle(fontFamily: 'Tajawal')),
            subtitle: Text(
              DateFormat('yyyy/MM/dd', 'ar').format(startDate),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => startDate = picked);
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('تاريخ النهاية',
                style: TextStyle(fontFamily: 'Tajawal')),
            subtitle: Text(
              DateFormat('yyyy/MM/dd', 'ar').format(endDate),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => endDate = picked);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'start': startDate, 'end': endDate});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('تطبيق', style: TextStyle(fontFamily: 'Tajawal')),
        ),
      ],
    );
  }
}
