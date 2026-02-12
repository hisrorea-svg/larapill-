import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/recent_transactions_log.dart';

class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'جميع المعاملات',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد معاملات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: transaction.isIncome
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction.isIncome
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: transaction.isIncome
                          ? AppColors.success
                          : AppColors.error,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                          .format(transaction.date),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  trailing: Text(
                    NumberFormat.currency(
                      symbol: 'د.ع',
                      decimalDigits: 0,
                      locale: 'ar_IQ',
                    ).format(transaction.amount),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.isIncome
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text(
            'خطأ في تحميل المعاملات',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      ),
    );
  }
}
