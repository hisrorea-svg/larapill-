import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/dashboard_service.dart';

class ProductsPieChart extends StatelessWidget {
  const ProductsPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أكثر المنتجات مبيعاً',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: DashboardService().getTopSellingProducts(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد بيانات لعرضها',
                      style:
                          GoogleFonts.tajawal(color: AppColors.textSecondary),
                    ),
                  );
                }

                final productData = snapshot.data!;
                final productNames = productData.keys.toList();
                final colors = [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                  Colors.cyan,
                  Colors.pink,
                  Colors.teal,
                  Colors.brown,
                  Colors.indigo,
                  Colors.lime,
                  Colors.amber,
                ];

                // Use StatefulBuilder to manage the local state of the chart interaction
                return StatefulBuilder(
                  builder: (context, setChartState) {
                    int touchedIndex = -1;

                    return Row(
                      children: [
                        // ✅ Pie Chart - نسبة أصغر
                        Expanded(
                          flex: 8, // ✅ كان 3، صار 2
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                      setChartState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections:
                                      List.generate(productNames.length, (i) {
                                    final isTouched = i == touchedIndex;
                                    final fontSize = isTouched ? 10.0 : 9.0;
                                    final radius = isTouched ? 70.0 : 60.0;
                                    final productName = productNames[i];
                                    final value = productData[productName]!;

                                    return PieChartSectionData(
                                      color: colors[i % colors.length],
                                      value: value,
                                      // عند التحويم يظهر اسم المنتج
                                      title: isTouched
                                          ? productName
                                          : '${value.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      titlePositionPercentageOffset:
                                          isTouched ? 0.55 : 0.5,
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ✅ Legend - نسبة أكبر
                        Expanded(
                          flex: 3, // ✅ كان 2، صار 3
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(productNames.length, (i) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colors[i % colors.length],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        productNames[i],
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11,
                                          fontWeight: touchedIndex == i
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
