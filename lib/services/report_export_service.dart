import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../core/config/pharmacy_info.dart';
import '../../core/theme/app_colors.dart' as app;

class ReportExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// تصدير تقرير كامل بصيغة PDF
  static Future<String> exportToPDF({
    required String period,
    required Map<String, dynamic> salesData,
    required Map<String, dynamic> inventoryData,
    required Map<String, dynamic> financialData,
    required Map<String, dynamic> debtsData,
  }) async {
    // تحميل معلومات الصيدلية من قاعدة البيانات
    await PharmacyInfo.loadFromDatabase();

    final pdf = pw.Document();

    // تحميل الخطوط العربية
    final fontData = await rootBundle.load("assets/fonts/Tajawal-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Tajawal-Bold.ttf");
    final arabicFont = pw.Font.ttf(fontData);
    final arabicBoldFont = pw.Font.ttf(boldFontData);

    final arabicTheme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicBoldFont,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: arabicTheme,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // العنوان الرئيسي مع خلفية ملونة
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [
                        PdfColor.fromInt(0xFF1DD1A1), // primary
                        PdfColor.fromInt(0xFF00A085), // primaryDark
                      ],
                    ),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        PharmacyInfo.name.isNotEmpty
                            ? PharmacyInfo.name
                            : 'صيدلية LaRaPill',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        PharmacyInfo.englishName.isNotEmpty
                            ? PharmacyInfo.englishName
                            : 'LaRaPill Pharmacy',
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'التقرير الشامل',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          'الفترة: ${_getPeriodName(period)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1DD1A1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'تاريخ الإصدار: ${_dateFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // جدول المبيعات
                _buildColorfulTable(
                  'تقرير المبيعات',
                  PdfColor.fromInt(app.AppColors.primary.toARGB32()),
                  [
                    ['البيان', 'القيمة'],
                    ['عدد الفواتير', '${salesData['count']} فاتورة'],
                    [
                      'إجمالي المبيعات',
                      '${_numberFormat.format(salesData['total'])} د.ع'
                    ],
                    [
                      'صافي الربح',
                      '${_numberFormat.format(salesData['profit'])} د.ع'
                    ],
                  ],
                ),

                pw.SizedBox(height: 15),

                // جدول المخزون
                _buildColorfulTable(
                  'تقرير المخزون',
                  PdfColor.fromInt(app.AppColors.secondary.toARGB32()),
                  [
                    ['البيان', 'القيمة'],
                    ['إجمالي المنتجات', '${inventoryData['total']} منتج'],
                    ['منتجات منخفضة', '${inventoryData['lowStock']} منتج'],
                    ['منتجات نفذت', '${inventoryData['outOfStock']} منتج'],
                  ],
                ),

                pw.SizedBox(height: 15),

                // صف يحتوي على جدولين جنباً إلى جنب
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // جدول المالية
                    pw.Expanded(
                      child: _buildColorfulTable(
                        'التقرير المالي',
                        PdfColor.fromInt(app.AppColors.info.toARGB32()),
                        [
                          ['البيان', 'المبلغ'],
                          [
                            'الإيرادات',
                            '${_numberFormat.format(financialData['revenue'])} د.ع'
                          ],
                          [
                            'صافي الربح',
                            '${_numberFormat.format(financialData['profit'])} د.ع'
                          ],
                          [
                            'المصروفات',
                            '${_numberFormat.format(financialData['expenses'])} د.ع'
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    // جدول الديون
                    pw.Expanded(
                      child: _buildColorfulTable(
                        'تقرير الديون',
                        PdfColor.fromInt(app.AppColors.error.toARGB32()),
                        [
                          ['البيان', 'القيمة'],
                          [
                            'إجمالي الديون',
                            '${_numberFormat.format(debtsData['total'])} د.ع'
                          ],
                          ['عدد العملاء', '${debtsData['count']} عميل'],
                          [
                            'المبلغ المدفوع',
                            '${_numberFormat.format(debtsData['paid'])} د.ع'
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // التذييل
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'تم إنشاء هذا التقرير تلقائياً بواسطة نظام LaRaPill',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'نظام إدارة الصيدليات الاحترافي',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'تقرير_${period}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// تصدير تقرير بصيغة Excel
  static Future<String> exportToExcel({
    required String period,
    required Map<String, dynamic> salesData,
    required Map<String, dynamic> inventoryData,
    required Map<String, dynamic> financialData,
    required Map<String, dynamic> debtsData,
  }) async {
    final excel = xl.Excel.createExcel();

    // حذف الورقة الافتراضية
    excel.delete('Sheet1');

    // ورقة المبيعات
    final salesSheet = excel['المبيعات'];
    salesSheet.isRTL = true;
    _addExcelRow(salesSheet, ['البيان', 'القيمة'], isHeader: true);
    _addExcelRow(salesSheet, ['عدد الفواتير', salesData['count'].toString()]);
    _addExcelRow(salesSheet,
        ['إجمالي المبيعات', '${_numberFormat.format(salesData['total'])} د.ع']);
    _addExcelRow(salesSheet,
        ['صافي الربح', '${_numberFormat.format(salesData['profit'])} د.ع']);

    // ورقة المخزون
    final inventorySheet = excel['المخزون'];
    inventorySheet.isRTL = true;
    _addExcelRow(inventorySheet, ['البيان', 'القيمة'], isHeader: true);
    _addExcelRow(
        inventorySheet, ['إجمالي المنتجات', inventoryData['total'].toString()]);
    _addExcelRow(inventorySheet,
        ['منتجات منخفضة', inventoryData['lowStock'].toString()]);
    _addExcelRow(inventorySheet,
        ['منتجات نفذت', inventoryData['outOfStock'].toString()]);

    // الورقة المالية
    final financialSheet = excel['المالية'];
    financialSheet.isRTL = true;
    _addExcelRow(financialSheet, ['البيان', 'القيمة'], isHeader: true);
    _addExcelRow(financialSheet,
        ['الإيرادات', '${_numberFormat.format(financialData['revenue'])} د.ع']);
    _addExcelRow(financialSheet,
        ['صافي الربح', '${_numberFormat.format(financialData['profit'])} د.ع']);
    _addExcelRow(financialSheet, [
      'المصروفات',
      '${_numberFormat.format(financialData['expenses'])} د.ع'
    ]);

    // ورقة الديون
    final debtsSheet = excel['الديون'];
    debtsSheet.isRTL = true;
    _addExcelRow(debtsSheet, ['البيان', 'القيمة'], isHeader: true);
    _addExcelRow(debtsSheet,
        ['إجمالي الديون', '${_numberFormat.format(debtsData['total'])} د.ع']);
    _addExcelRow(debtsSheet, ['عدد العملاء', debtsData['count'].toString()]);
    _addExcelRow(debtsSheet,
        ['المبلغ المدفوع', '${_numberFormat.format(debtsData['paid'])} د.ع']);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'تقرير_${period}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');

    final excelBytes = excel.encode();
    if (excelBytes != null) {
      await file.writeAsBytes(excelBytes);
    }

    return file.path;
  }

  /// تصدير تقرير بصيغة CSV
  static Future<String> exportToCSV({
    required String period,
    required Map<String, dynamic> salesData,
    required Map<String, dynamic> inventoryData,
    required Map<String, dynamic> financialData,
    required Map<String, dynamic> debtsData,
  }) async {
    final List<List<dynamic>> rows = [
      ['تقرير LaRaPill الشامل'],
      ['الفترة', _getPeriodName(period)],
      ['تاريخ الإصدار', _dateFormat.format(DateTime.now())],
      [],
      ['=== تقرير المبيعات ==='],
      ['عدد الفواتير', salesData['count']],
      ['إجمالي المبيعات', '${_numberFormat.format(salesData['total'])} د.ع'],
      ['صافي الربح', '${_numberFormat.format(salesData['profit'])} د.ع'],
      [],
      ['=== تقرير المخزون ==='],
      ['إجمالي المنتجات', inventoryData['total']],
      ['منتجات منخفضة', inventoryData['lowStock']],
      ['منتجات نفذت', inventoryData['outOfStock']],
      [],
      ['=== التقرير المالي ==='],
      ['الإيرادات', '${_numberFormat.format(financialData['revenue'])} د.ع'],
      ['صافي الربح', '${_numberFormat.format(financialData['profit'])} د.ع'],
      ['المصروفات', '${_numberFormat.format(financialData['expenses'])} د.ع'],
      [],
      ['=== تقرير الديون ==='],
      ['إجمالي الديون', '${_numberFormat.format(debtsData['total'])} د.ع'],
      ['عدد العملاء', debtsData['count']],
      ['المبلغ المدفوع', '${_numberFormat.format(debtsData['paid'])} د.ع'],
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'تقرير_${period}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }

  /// فتح الملف المصدّر
  static Future<void> openFile(String filePath) async {
    await OpenFile.open(filePath);
  }

  // Helper methods
  static pw.Widget _buildColorfulTable(
    String title,
    PdfColor headerColor,
    List<List<String>> data,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // عنوان الجدول
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: headerColor,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        // محتوى الجدول
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
          children: data.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isHeader = index == 0;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isHeader
                    ? headerColor.shade(0.8)
                    : (index % 2 == 0 ? PdfColors.white : PdfColors.grey100),
              ),
              children: row.map((cell) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(
                      fontSize: isHeader ? 12 : 11,
                      fontWeight:
                          isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: isHeader ? headerColor : PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ],
    );
  }

  static void _addExcelRow(xl.Sheet sheet, List<dynamic> values,
      {bool isHeader = false}) {
    sheet.appendRow(values.map((e) => xl.TextCellValue(e.toString())).toList());
  }

  static String _getPeriodName(String period) {
    switch (period) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذا العام';
      default:
        return period;
    }
  }
}
