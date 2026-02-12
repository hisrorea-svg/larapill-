import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/drift/daos/sales_drift_dao.dart';
import '../screens/all_transactions_screen.dart';

/// موفر لأحدث المعاملات (المبيعات حالياً)
final recentTransactionsProvider =
    FutureProvider<List<TransactionItem>>((ref) async {
  final salesDao = ref.watch(salesDriftDaoProvider);
  // جلب آخر 10 مبيعات
  final allSales = await salesDao.findAll();

  // ترتيب تنازلي حسب التاريخ
  allSales.sort((a, b) => b.date.compareTo(a.date));

  return allSales.take(10).map((sale) {
    return TransactionItem(
      id: sale.id.toString(),
      type: 'sale',
      amount: sale.total,
      date: sale.date,
      description: 'فاتورة #${sale.id} - ${sale.customerName ?? "عميل نقدي"}',
      isIncome: true,
    );
  }).toList();
});

class TransactionItem {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final bool isIncome;

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.isIncome,
  });
}

class RecentTransactionsLog extends ConsumerWidget {
  const RecentTransactionsLog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل المعاملات الأخيرة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'رقم المعاملة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'الوصف',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'التاريخ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المبلغ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'الحالة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Table body
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'لا توجد معاملات حديثة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: transactions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final formattedId = tx.isIncome
                      ? '#SALE-${tx.id.padLeft(4, '0')}'
                      : '#EXP-${tx.id.padLeft(4, '0')}';
                  final statusLabel = tx.isIncome ? 'مكتملة' : 'مصروف';
                  final statusColor =
                      tx.isIncome ? AppColors.success : AppColors.warning;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // رقم المعاملة
                        Expanded(
                          flex: 2,
                          child: Text(
                            formattedId,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        // الوصف
                        Expanded(
                          flex: 3,
                          child: Text(
                            tx.description,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // التاريخ
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat('yyyy/MM/dd', 'ar').format(tx.date),
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        // المبلغ
                        Expanded(
                          flex: 2,
                          child: Text(
                            NumberFormat.currency(
                                    symbol: 'د.ع',
                                    decimalDigits: 0,
                                    locale: 'ar_IQ')
                                .format(tx.amount),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: tx.isIncome
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                        // الحالة (badge)
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'خطأ في تحميل السجل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
