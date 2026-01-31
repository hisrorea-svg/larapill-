import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/services/printer_service.dart';
import '../../data/models/daily_purchase_request.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final List<DailyPurchaseRequest> requests;
  final String? supplierName;

  const PdfPreviewScreen({
    super.key,
    required this.requests,
    this.supplierName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'معاينة طلبية الشراء',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await PrinterService.instance.shareDailyPurchaseRequests(
                  requests: requests,
                  supplierName: supplierName,
                );
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(context, 'خطأ في المشاركة: $e');
                }
              }
            },
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) =>
            PrinterService.instance.generateDailyPurchasePdfBytes(
          requests: requests,
          supplierName: supplierName,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: false,
        allowPrinting: true,
        pdfFileName:
            'طلبية_شراء_${DateTime.now().toString().split(' ')[0]}.pdf',
        onPrinted: (context) {
          AppToast.success(context, 'تمت الطباعة بنجاح');
        },
        onShared: (context) {
          AppToast.success(context, 'تمت المشاركة بنجاح');
        },
      ),
    );
  }
}
