import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/dashboard_service.dart';

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
          Text(
            'توزيع المنتجات حسب الفئة',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: DashboardService().getProductsCategoryData(),
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

                final categoryData = snapshot.data!;
                final categories = categoryData.keys.toList();
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
                                      List.generate(categories.length, (i) {
                                    final isTouched = i == touchedIndex;
                                    final fontSize = isTouched ? 14.0 : 11.0;
                                    final radius = isTouched ? 65.0 : 60.0;
                                    final category = categories[i];
                                    final value = categoryData[category]!;

                                    return PieChartSectionData(
                                      color: colors[i % colors.length],
                                      value: value,
                                      title: '${value.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: GoogleFonts.tajawal(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ✅ Legend - نسبة أكبر
                        Expanded(
                          flex: 3, // ✅ كان 2، صار 3
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(categories.length, (i) {
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
                                        categories[i],
                                        style: GoogleFonts.tajawal(
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
