import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../core/theme/app_colors.dart';
import '../models/daily_purchase_request.dart';
import '../providers/daily_purchase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/printer_service.dart';
import 'pdf_preview_screen.dart';

class PurchaseRequestsTable extends ConsumerWidget {
  final List<DailyPurchaseRequest> requests;

  const PurchaseRequestsTable({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      headingRowHeight: 52,
      dataRowHeight: 45,
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      headingRowColor:
          WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
      dataRowColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.1);
          }
          return null;
        },
      ),
      columns: [
        DataColumn2(
          label: Center(
            child: Text('ت',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          fixedWidth: 35,
        ),
        DataColumn2(
          label: Center(
            child: Text('اسم المنتج',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Center(
            child: Text('الوحدة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          size: ColumnSize.M,
          fixedWidth: 120,
        ),
        DataColumn2(
          label: Center(
            child: Text('الكمية',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          fixedWidth: 80,
        ),
        DataColumn2(
          label: Center(
            child: Text('الإجراءات',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          fixedWidth: 200,
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
                  child: Text(
                    (index + 1).toString(),
                    style: GoogleFonts.tajawal(fontSize: 13),
                  ),
                ),
              ),

              // اسم المنتج
              DataCell(
                Center(
                  child: SizedBox(
                    width: 220,
                    child: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // الوحدة
              DataCell(
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.unit ?? 'غير محدد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.requestedQuantity > 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.requestedQuantity.toInt().toString(),
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: item.requestedQuantity > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // الإجراءات
              DataCell(
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'تعديل',
                        icon: const Icon(Icons.edit,
                            color: Colors.orangeAccent, size: 20),
                        onPressed: () {
                          _showEditDialog(context, ref, item);
                        },
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent, size: 20),
                        onPressed: () {
                          _handleDelete(context, ref, item);
                        },
                      ),
                      IconButton(
                        tooltip: 'معاينة PDF',
                        icon: const Icon(Icons.picture_as_pdf,
                            color: AppColors.secondary, size: 20),
                        onPressed: () {
                          _previewPdf(context, ref, item);
                        },
                      ),
                      IconButton(
                        tooltip: 'مشاركة',
                        icon: const Icon(Icons.share,
                            color: Colors.green, size: 20),
                        onPressed: () {
                          _sharePdf(context, ref, item);
                        },
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 8),
            Text('تأكيد الحذف',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل تريد حذف "${request.productName}" من الطلبية؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(dailyPurchaseNotifierProvider.notifier)
          .deleteRequest(request.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف ${request.productName}',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        title: Text('تعديل الكمية',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'الكمية المطلوبة',
            labelStyle: GoogleFonts.tajawal(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.tajawal(fontSize: 16),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal())),
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
            child: Text('حفظ', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  void _previewPdf(
      BuildContext context, WidgetRef ref, DailyPurchaseRequest request) async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);
    await requestsAsync.whenOrNull(data: (requests) async {
      if (requests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('لا توجد طلبات للمعاينة', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.warning,
        ));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            requests: requests,
            supplierName: request.supplierName,
          ),
        ),
      );
    });
  }

  void _sharePdf(
      BuildContext context, WidgetRef ref, DailyPurchaseRequest request) async {
    final requestsAsync = ref.read(dailyPurchaseNotifierProvider);
    await requestsAsync.whenOrNull(data: (requests) async {
      if (requests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('لا توجد طلبات للمشاركة', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.warning,
        ));
        return;
      }

      await PrinterService.instance.shareDailyPurchaseRequests(
        requests: requests,
        supplierName: request.supplierName,
      );
    });
  }
}
