import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/customer_debt.dart';
import '../../../database/daos/customer_debt_dao.dart';
import '../widgets/debt_list_item.dart';
import '../widgets/payment_dialog.dart';

/// 💰 Provider لجلب قائمة الديون
final debtsProvider = FutureProvider<List<CustomerDebt>>((ref) async {
  final dao = CustomerDebtDAO();
  return await dao.getAllDebts(onlyWithDebt: true);
});

/// 💰 Provider لإحصائيات الديون
final debtStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dao = CustomerDebtDAO();
  final totalDebts = await dao.getTotalDebts();
  final debtorsCount = await dao.getDebtorsCount();

  return {
    'totalDebts': totalDebts,
    'debtorsCount': debtorsCount,
  };
});

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // تحديث البيانات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDebts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshDebts() {
    ref.invalidate(debtsProvider);
    ref.invalidate(debtStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final statsAsync = ref.watch(debtStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Statistics Cards
              _buildStatsCards(statsAsync),
              const SizedBox(height: 24),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Debts List
              Expanded(
                child: _buildDebtsList(debtsAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الديون',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'متابعة ديون العملاء وتسجيل الدفعات',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primary),
          tooltip: 'تحديث',
          onPressed: _refreshDebts,
        ),
      ],
    );
  }

  Widget _buildStatsCards(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final totalDebts = stats['totalDebts'] as double;
        final debtorsCount = stats['debtorsCount'] as int;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'إجمالي الديون',
                value: '${totalDebts.toInt()} د.ع',
                icon: Icons.money_off,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'عدد المدينين',
                value: debtorsCount.toString(),
                icon: Icons.people,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'خطأ في تحميل الإحصائيات',
          style: GoogleFonts.tajawal(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث عن عميل...',
        hintStyle: GoogleFonts.tajawal(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      style: GoogleFonts.tajawal(),
      onChanged: (value) {
        setState(() => _searchQuery = value.toLowerCase());
      },
    );
  }

  Widget _buildDebtsList(AsyncValue<List<CustomerDebt>> debtsAsync) {
    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return _buildEmptyState();
        }

        final filteredDebts = debts.where((debt) {
          if (_searchQuery.isEmpty) return true;
          return debt.customerName.toLowerCase().contains(_searchQuery) ||
              (debt.customerPhone?.toLowerCase().contains(_searchQuery) ??
                  false);
        }).toList();

        if (filteredDebts.isEmpty) {
          return Center(
            child: Text(
              'لا توجد نتائج للبحث',
              style: GoogleFonts.tajawal(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDebts.length,
          itemBuilder: (context, index) {
            final debt = filteredDebts[index];
            return DebtListItem(
              debt: debt,
              onPaymentTap: () => _showPaymentDialog(debt),
              onRefresh: _refreshDebts,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل البيانات',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.tajawal(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد ديون مسجلة',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع المبيعات مدفوعة بالكامل 🎉',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
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
          _refreshDebts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تسجيل الدفعة بنجاح ✓',
                  style: GoogleFonts.tajawal(),
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }
}
