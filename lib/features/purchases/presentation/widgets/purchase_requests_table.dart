import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/daily_purchase_request.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/daily_purchase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseRequestsTable extends ConsumerWidget {
  final List<DailyPurchaseRequest> requests;

  const PurchaseRequestsTable({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DataTable2(
      columnSpacing: 16,
      horizontalMargin: 16,
      minWidth: 600,
      headingRowHeight: 48,
      dataRowHeight: 52,
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      headingRowColor:
          WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.1);
          }
          return null;
        },
      ),
      columns: const [
        DataColumn2(
          label: Center(
            child: Text('#',
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ),
          fixedWidth: 45,
        ),
        DataColumn2(
          label: Text('اسم المنتج',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Center(
            child: Text('الوحدة',
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ),
          fixedWidth: 100,
        ),
        DataColumn2(
          label: Center(
            child: Text('الكمية',
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ),
          fixedWidth: 80,
        ),
        DataColumn2(
          label: Center(
            child: Text('',
                style: TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
          fixedWidth: 100,
        ),
      ],
      rows: List<DataRow>.generate(
        requests.length,
        (index) {
          final item = requests[index];
          return DataRow(
            color: WidgetStateProperty.all(
              index.isEven ? Colors.grey.shade50 : Colors.white,
            ),
            cells: [
              // رقم تسلسلي
              DataCell(
                Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // اسم المنتج - موسّع
              DataCell(
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // الوحدة
              DataCell(
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.unit ?? 'غير محدد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // الكمية
              DataCell(
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      item.requestedQuantity.toInt().toString(),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // الإجراءات - زرين فقط
              DataCell(
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر تعديل
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        color: Colors.orange,
                        tooltip: 'تعديل الكمية',
                        onTap: () => _showEditDialog(context, ref, item),
                      ),
                      const SizedBox(width: 8),
                      // زر حذف
                      _ActionButton(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        tooltip: 'حذف',
                        onTap: () => _handleDelete(context, ref, item),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========= الإجراءات =========

  void _handleDelete(
      BuildContext context, WidgetRef ref, DailyPurchaseRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 8),
            Text('تأكيد الحذف',
                style: TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل تريد حذف "${request.productName}" من الطلبية؟',
          style: const TextStyle(
            fontFamily: 'Tajawal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(dailyPurchaseNotifierProvider.notifier)
          .deleteRequest(request.id);

      if (context.mounted) {
        AppToast.success(context, 'تم حذف ${request.productName}');
      }
    }
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, DailyPurchaseRequest request) {
    final controller = TextEditingController(
        text: request.requestedQuantity.toInt().toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل الكمية',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'الكمية المطلوبة',
            labelStyle: const TextStyle(
              fontFamily: 'Tajawal',
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                  ))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null && qty >= 0) {
                ref
                    .read(dailyPurchaseNotifierProvider.notifier)
                    .updateQuantity(request.id, qty);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
        ],
      ),
    );
  }
}

/// زر إجراء صغير وأنيق للجدول
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => isHovered = false);
      },
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isHovered
                  ? widget.color
                  : widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: isHovered ? Colors.white : widget.color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
