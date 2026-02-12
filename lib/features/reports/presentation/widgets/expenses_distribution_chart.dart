import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/expenses_provider.dart';

class ExpensesDistributionChart extends ConsumerStatefulWidget {
  const ExpensesDistributionChart({super.key});

  @override
  ConsumerState<ExpensesDistributionChart> createState() =>
      _ExpensesDistributionChartState();
}

class _ExpensesDistributionChartState
    extends ConsumerState<ExpensesDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'توزيع المصروفات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          expensesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('لا توجد بيانات'));
              }

              final total =
                  categories.fold(0.0, (sum, item) => sum + item.amount);

              return Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                if (!mounted) return;
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: List.generate(categories.length, (i) {
                              final isTouched = i == touchedIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 60.0 : 50.0;
                              final category = categories[i];
                              final percentage =
                                  (category.amount / total * 100).round();

                              return PieChartSectionData(
                                color: category.color,
                                value: category.amount,
                                title: '$percentage%',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Tajawal',
                                ),
                              );
                            }),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'الإجمالي',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                NumberFormat.compact(locale: 'en_US')
                                    .format(total),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  Column(
                    children: categories.map((category) {
                      final percentage =
                          (category.amount / total * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.label,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              NumberFormat.compact(locale: 'en_US')
                                  .format(category.amount),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('خطأ في التحميل')),
          ),
        ],
      ),
    );
  }
}
