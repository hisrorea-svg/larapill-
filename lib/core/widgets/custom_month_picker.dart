import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Month/Year Picker مع تصميم محسّن
/// - حواف دائرية
/// - اختيار الشهر مباشر بدون OK
/// - اختيار السنة سهل
/// - الإلغاء بالضغط خارج المربع
Future<DateTime?> showCustomMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true, // ✅ الإلغاء بالضغط خارج المربع
    builder: (context) => _CustomMonthPickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _CustomMonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomMonthPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomMonthPickerDialog> createState() =>
      _CustomMonthPickerDialogState();
}

class _CustomMonthPickerDialogState extends State<_CustomMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late PageController _yearController;

  // أسماء الأشهر بالإنجليزية المختصرة
  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _yearController = PageController(
      initialPage: _selectedYear - widget.firstDate.year,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════ اختيار السنة ═══════════════
            _buildYearSelector(),
            const SizedBox(height: 16),

            // ═══════════════ شبكة الأشهر ═══════════════
            _buildMonthsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    final availableYears = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر السنة السابقة
          IconButton(
            onPressed: _selectedYear > widget.firstDate.year
                ? () => setState(() => _selectedYear--)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            iconSize: 28,
          ),

          // ✅ Dropdown سهل لاختيار السنة
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            items: availableYears.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (year) {
              if (year != null) {
                setState(() => _selectedYear = year);
              }
            },
          ),

          // زر السنة التالية
          IconButton(
            onPressed: _selectedYear < widget.lastDate.year
                ? () => setState(() => _selectedYear++)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected =
            _selectedYear == widget.initialDate.year && month == _selectedMonth;

        // التحقق من أن الشهر ضمن النطاق المسموح
        final monthDate = DateTime(_selectedYear, month);
        final isDisabled = monthDate.isBefore(
              DateTime(widget.firstDate.year, widget.firstDate.month),
            ) ||
            monthDate.isAfter(
              DateTime(widget.lastDate.year, widget.lastDate.month),
            );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    // ✅ اختيار مباشر بدون OK
                    Navigator.of(context).pop(DateTime(_selectedYear, month));
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDisabled
                        ? Colors.grey.shade200
                        : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _monthNames[index],
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDisabled
                          ? Colors.grey.shade400
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
