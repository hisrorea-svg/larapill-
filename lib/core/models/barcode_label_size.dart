import 'package:pdf/pdf.dart';

/// أحجام ملصقات الباركود الشائعة
enum BarcodeLabelSize {
  small('40mm × 25mm', 'شائع للصيدليات الصغيرة', 40, 25),
  medium('50mm × 30mm', 'متوسط - متعدد الاستخدامات', 50, 30),
  standard('60mm × 30mm', 'قياسي - الافتراضي', 60, 30),
  large('70mm × 40mm', 'كبير - للأدوية الكبيرة', 70, 40),
  custom('مخصص', 'حجم مخصص يدوياً', 60, 30); // قيم افتراضية للمخصص

  final String displayName;
  final String description;
  final double widthMm;
  final double heightMm;

  const BarcodeLabelSize(
    this.displayName,
    this.description,
    this.widthMm,
    this.heightMm,
  );

  /// تحويل إلى PdfPageFormat
  PdfPageFormat toPdfPageFormat({double? customWidth, double? customHeight}) {
    if (this == BarcodeLabelSize.custom &&
        customWidth != null &&
        customHeight != null) {
      return PdfPageFormat(
        customWidth * PdfPageFormat.mm,
        customHeight * PdfPageFormat.mm,
      );
    }
    return PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      heightMm * PdfPageFormat.mm,
    );
  }

  /// الحصول على الأبعاد كنص
  String get dimensionsText => '${widthMm.toInt()}mm × ${heightMm.toInt()}mm';
}
