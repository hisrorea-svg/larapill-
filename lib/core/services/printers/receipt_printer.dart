import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../features/pos/domain/entities/sale.dart';
import '../pharmacy_settings_service.dart';

class ReceiptPrinter {
  // طباعة فاتورة البيع
  static Future<void> printReceipt({
    required Sale sale,
    required List<Map<String, dynamic>> items,
    String? customerName,
    required double totalAmount,
    required double amountPaid,
    required double change,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';
      final pharmacyNameEn = settings['name_en'] ?? 'LaRaPill Pharmacy';
      final pharmacyPhone = settings['phone'] ?? '';

      final pdf = pw.Document();

      // تحميل خط عربي
      final arabicFont =
          await fontFromAssetBundle('assets/fonts/Tajawal-Regular.ttf');
      final arabicBoldFont =
          await fontFromAssetBundle('assets/fonts/Tajawal-Bold.ttf');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header - Thermal Printer Design (B&W)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        pharmacyNameAr,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        pharmacyNameEn,
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      if (pharmacyPhone.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          pharmacyPhone,
                          style: const pw.TextStyle(
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                // Invoice Title - Simple
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border.symmetric(
                      horizontal:
                          pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'فاتورة مبيعات',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),

                pw.SizedBox(height: 6),

                // Invoice Details - Compact
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'فاتورة: ${sale.id.length > 8 ? sale.id.substring(0, 8).toUpperCase() : sale.id.toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 8),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      sale.cashierName,
                      style: const pw.TextStyle(fontSize: 8),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      DateFormat('yyyy/MM/dd').format(sale.createdAt),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      DateFormat('hh:mm a').format(sale.createdAt),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (customerName != null && customerName.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'عميل: $customerName',
                    style: const pw.TextStyle(fontSize: 8),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],

                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.black, thickness: 1),

                // Products Table - Thermal Simple
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.6),
                    1: const pw.FlexColumnWidth(3.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        border:
                            pw.Border.all(color: PdfColors.black, width: 0.5),
                      ),
                      children: [
                        _buildTableCell('#',
                            bold: true, padding: 3, fontSize: 8),
                        _buildTableCell('الصنف',
                            bold: true, rtl: true, padding: 3, fontSize: 8),
                        _buildTableCell('كمية',
                            bold: true, rtl: true, padding: 3, fontSize: 8),
                        _buildTableCell('سعر',
                            bold: true, rtl: true, padding: 3, fontSize: 8),
                        _buildTableCell('مجموع',
                            bold: true, rtl: true, padding: 3, fontSize: 8),
                      ],
                    ),
                    // Items
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return pw.TableRow(
                        children: [
                          _buildTableCell('${index + 1}',
                              fontSize: 9, bold: true),
                          _buildTableCell(item['productName'],
                              rtl: true,
                              fontSize: 9,
                              bold: false,
                              allowWrap: true), // ✅ السماح بالالتفاف فقط للصنف
                          _buildTableCell(
                              '${item['quantity'].toStringAsFixed(0)}',
                              fontSize: 7,
                              bold: true),
                          _buildTableCell('${item['price'].toStringAsFixed(0)}',
                              fontSize: 7, bold: false),
                          _buildTableCell(
                            '${(item['quantity'] * item['price']).toStringAsFixed(0)}',
                            fontSize: 7,
                            bold: false,
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.black, thickness: 1),

                // Totals - Simple B&W with Smart Display
                pw.Column(
                  children: [
                    _buildSimpleTotalRow('الإجمالي:', totalAmount),
                    pw.SizedBox(height: 2),
                    _buildSimpleTotalRow('المدفوع:', amountPaid),
                    pw.Divider(thickness: 0.5, color: PdfColors.black),
                    pw.SizedBox(height: 2),
                    // ✅ عرض ذكي: إذا موجب = دين، إذا سالب = باقي
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 3, horizontal: 4),
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.black, width: 1.5),
                      ),
                      child: change > 0
                          ? _buildSimpleTotalRow('الدين:', change, bold: true)
                          : change < 0
                              ? _buildSimpleTotalRow('الباقي:', change.abs(),
                                  bold: true)
                              : _buildSimpleTotalRow('الباقي:', 0, bold: true),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.black, thickness: 2),

                // Footer - Simple
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'شكراً لزيارتكم',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Thank you for your visit',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'LaRaPill System',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('فشل في طباعة الفاتورة: $e');
    }
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    bool rtl = false,
    double padding = 2,
    double fontSize = 10,
    bool allowWrap = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        maxLines: allowWrap ? null : 1,
        overflow: allowWrap ? null : pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget _buildSimpleTotalRow(String label, double value,
      {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          '${value.toStringAsFixed(0)} د.ع',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }
}
