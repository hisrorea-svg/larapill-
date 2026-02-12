import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../purchases/presentation/providers/purchases_drift_providers.dart';
import '../../../debts/presentation/providers/debts_providers.dart';

class DebtsOverviewTable extends ConsumerWidget {
  const DebtsOverviewTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'جدول الديون',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: 'العملاء (لهم)'),
                        Tab(text: 'الموردين (عليهم)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 350,
              child: TabBarView(
                children: [
                  _buildCustomersTable(ref),
                  _buildSuppliersTable(ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTable(WidgetRef ref) {
    final customersAsync = ref.watch(topDebtorsProvider);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return _buildEmptyState('لا توجد ديون عملاء', ref: ref);
        }

        // Data is already sorted by provider
        final displayedCustomers = customers;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: displayedCustomers.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final debtor = displayedCustomers[index];
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debtor.customerName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        debtor.customerPhone ?? 'لا يوجد رقم',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                              symbol: 'د.ع', decimalDigits: 0, locale: 'ar_IQ')
                          .format(debtor.remainingDebt),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      DateFormat('yy/MM/dd').format(debtor.lastTransactionDate),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState('خطأ في تحميل البيانات'),
    );
  }

  Widget _buildSuppliersTable(WidgetRef ref) {
    final suppliersAsync = ref.watch(activeSuppliersProvider);

    return suppliersAsync.when(
      data: (suppliers) {
        // Filter those with balance > 0
        final creditors = suppliers.where((s) => s.balance > 0).toList();

        if (creditors.isEmpty) {
          return _buildEmptyState('لا توجد مستحقات موردين', ref: ref);
        }

        // Sort by balance descending
        creditors.sort((a, b) => b.balance.compareTo(a.balance));
        final displayedCreditors = creditors.take(5).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: displayedCreditors.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final creditor = displayedCreditors[index];
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  child: const Icon(Icons.local_shipping,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creditor.name,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          creditor.paymentTypeLabel,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(
                          symbol: 'د.ع', decimalDigits: 0, locale: 'ar_IQ')
                      .format(creditor.balance),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState('خطأ في تحميل البيانات'),
    );
  }

  Widget _buildEmptyState(String message, {WidgetRef? ref}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inbox_outlined,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'لم يتم تسجيل أي بيانات حتى الآن',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (ref != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(topDebtorsProvider);
                ref.invalidate(activeSuppliersProvider);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'تحديث البيانات',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
