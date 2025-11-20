import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../features/purchases/models/daily_purchase_request.dart';
import '../pharmacy_settings_service.dart';

class ReportPrinter {
  // طباعة طلبات الشراء اليومية
  static Future<void> printDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';
      final pharmacyNameEn = settings['name_en'] ?? 'LaRaPill Pharmacy';

      final pdf = await _generateDailyPurchasePdf(
        requests: requests,
        supplierName: supplierName,
        pharmacyNameAr: pharmacyNameAr,
        pharmacyNameEn: pharmacyNameEn,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('فشل في طباعة طلبية الشراء: $e');
    }
  }

  // معاينة طلبات الشراء اليومية قبل الطباعة - إرجاع البيانات للمعاينة
  static Future<Uint8List> generateDailyPurchasePdfBytes({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';
      final pharmacyNameEn = settings['name_en'] ?? 'LaRaPill Pharmacy';

      final pdf = await _generateDailyPurchasePdf(
        requests: requests,
        supplierName: supplierName,
        pharmacyNameAr: pharmacyNameAr,
        pharmacyNameEn: pharmacyNameEn,
      );

      return pdf.save();
    } catch (e) {
      throw Exception('فشل في توليد PDF: $e');
    }
  }

  // معاينة طلبات الشراء اليومية قبل الطباعة (مع نافذة طباعة)
  static Future<void> previewDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';
      final pharmacyNameEn = settings['name_en'] ?? 'LaRaPill Pharmacy';

      final pdf = await _generateDailyPurchasePdf(
        requests: requests,
        supplierName: supplierName,
        pharmacyNameAr: pharmacyNameAr,
        pharmacyNameEn: pharmacyNameEn,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name:
            'طلبية_شراء_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      throw Exception('فشل في معاينة طلبية الشراء: $e');
    }
  }

  // مشاركة طلبات الشراء اليومية
  static Future<void> shareDailyPurchaseRequests({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';
      final pharmacyNameEn = settings['name_en'] ?? 'LaRaPill Pharmacy';

      final pdf = await _generateDailyPurchasePdf(
        requests: requests,
        supplierName: supplierName,
        pharmacyNameAr: pharmacyNameAr,
        pharmacyNameEn: pharmacyNameEn,
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'طلبية_شراء_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة طلبية الشراء: $e');
    }
  }

  // توليد PDF لطلبات الشراء اليومية
  static Future<pw.Document> _generateDailyPurchasePdf({
    required List<DailyPurchaseRequest> requests,
    String? supplierName,
    required String pharmacyNameAr,
    required String pharmacyNameEn,
  }) async {
    final pdf = pw.Document();

    // تحميل خط عربي
    final arabicFont = await PdfGoogleFonts.tajawalRegular();
    final arabicBoldFont = await PdfGoogleFonts.tajawalBold();

    final now = DateTime.now();
    final totalQuantity = requests.fold<double>(
      0,
      (sum, item) => sum + item.requestedQuantity,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '$pharmacyNameAr / $pharmacyNameEn',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'طلبية شراء يومية / Daily Purchase Order',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // معلومات الطلبية
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'التاريخ: ${DateFormat('yyyy/MM/dd').format(now)}',
                          style: const pw.TextStyle(fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'الوقت: ${DateFormat('HH:mm').format(now)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (supplierName != null && supplierName.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'المورد: $supplierName',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'عدد الأصناف: ${requests.length}',
                          style: const pw.TextStyle(fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'الكمية الإجمالية: ${totalQuantity.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // جدول المنتجات
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(5),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('#', bold: true, padding: 8),
                      _buildTableCell('اسم المنتج',
                          bold: true, rtl: true, padding: 8),
                      _buildTableCell('الكمية',
                          bold: true, rtl: true, padding: 8),
                    ],
                  ),
                  // Items
                  ...requests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    // دمج الكمية مع الوحدة
                    final quantityText = request.unit != null &&
                            request.unit!.isNotEmpty
                        ? '${request.requestedQuantity.toStringAsFixed(0)} ${request.unit}'
                        : request.requestedQuantity.toStringAsFixed(0);

                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}', padding: 8),
                        _buildTableCell(
                          request.productName,
                          rtl: true,
                          padding: 8,
                        ),
                        _buildTableCell(
                          quantityText,
                          rtl: true,
                          padding: 8,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Spacer(),
              pw.Divider(thickness: 2),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'LaRaPill System',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    bool rtl = false,
    double padding = 2,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }
}
