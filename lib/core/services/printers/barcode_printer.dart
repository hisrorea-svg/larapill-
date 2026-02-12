import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/barcode_type.dart';
import '../../models/barcode_label_size.dart';
import '../pharmacy_settings_service.dart';

class BarcodePrinter {
  /// طباعة باركود منتج - نسخة محسّنة
  static Future<void> printProductBarcode({
    required String barcode,
    required BarcodeType barcodeType,
    String? productName,
    double? price,
    BarcodeLabelSize labelSize = BarcodeLabelSize.standard,
    double? customWidth,
    double? customHeight,
    bool includePrice = false,
    int copies = 1,
  }) async {
    try {
      final settings =
          await PharmacySettingsService.instance.getPharmacySettings();
      final pharmacyNameAr = settings['name_ar'] ?? 'صيدلية فارماكليك';

      final pdf = pw.Document();

      // تحميل الخط العربي
      final arabicFont =
          await fontFromAssetBundle('assets/fonts/Tajawal-Regular.ttf');
      final arabicBoldFont =
          await fontFromAssetBundle('assets/fonts/Tajawal-Bold.ttf');

      // تحديد حجم الملصق
      final format = labelSize.toPdfPageFormat(
        customWidth: customWidth,
        customHeight: customHeight,
      );

      // تحويل BarcodeType إلى pw.Barcode object للطباعة
      final barcodeObj = _getBarcodeForPrinting(barcodeType);

      for (int i = 0; i < (copies <= 0 ? 1 : copies); i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(
              base: arabicFont,
              bold: arabicBoldFont,
            ),
            build: (context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(5), // Quiet Zone
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // اسم الصيدلية
                    pw.Text(
                      pharmacyNameAr,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),

                    // اسم المنتج
                    if (productName != null && productName.isNotEmpty)
                      pw.Text(
                        productName,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                    // السعر (إذا مطلوب)
                    if (includePrice && price != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 1),
                        child: pw.Text(
                          '${price.toStringAsFixed(0)} د.ع',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),

                    pw.SizedBox(height: 3),

                    // الباركود - مع مساحة مرنة
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.BarcodeWidget(
                          barcode: barcodeObj,
                          data: barcode,
                          width: format.availableWidth * 0.85,
                          height: _calculateBarcodeHeight(
                              barcodeType, format, includePrice),
                          drawText: false, // لا نعرض النص تحت الباركود
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      throw Exception('فشل في طباعة الباركود: $e');
    }
  }

  /// تحويل BarcodeType إلى pw.Barcode للطباعة
  static pw.Barcode _getBarcodeForPrinting(BarcodeType type) {
    switch (type) {
      case BarcodeType.ean13:
        return pw.Barcode.ean13();
      case BarcodeType.ean8:
        return pw.Barcode.ean8();
      case BarcodeType.upcA:
        return pw.Barcode.upcA();
      case BarcodeType.upcE:
        return pw.Barcode.upcE();
      case BarcodeType.code128:
        return pw.Barcode.code128();
      case BarcodeType.qrCode:
        return pw.Barcode.qrCode();
    }
  }

  /// حساب ارتفاع الباركود المناسب حسب النوع وحجم الملصق
  static double _calculateBarcodeHeight(
      BarcodeType type, PdfPageFormat format, bool includePrice) {
    // QR Code يحتاج مربع
    if (type == BarcodeType.qrCode) {
      return format.availableWidth * 0.65;
    }

    // باقي الأنواع خطية - تقليل الحجم عند إضافة السعر
    final availableHeight = format.availableHeight;
    final adjustment = includePrice ? 10.0 : 0.0; // تقليل 10 نقطة عند وجود سعر

    if (availableHeight > 100) {
      return 50.0 - adjustment; // ملصق كبير
    } else if (availableHeight > 70) {
      return 35.0 - adjustment; // ملصق متوسط
    } else {
      return 25.0 - adjustment; // ملصق صغير
    }
  }
}
