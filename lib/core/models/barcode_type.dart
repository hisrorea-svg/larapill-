import 'package:barcode/barcode.dart' as bc;

/// أنواع الباركود المدعومة
enum BarcodeType {
  ean13('EAN-13', 'الأكثر شيوعاً للأدوية في الشرق الأوسط وأوروبا'),
  ean8('EAN-8', 'للمنتجات الصغيرة'),
  upcA('UPC-A', 'الأكثر شيوعاً في الولايات المتحدة'),
  upcE('UPC-E', 'نسخة مضغوطة من UPC-A'),
  code128('Code 128', 'متعدد الاستخدامات - الافتراضي'),
  qrCode('QR Code', 'للمعلومات الموسعة');

  final String displayName;
  final String description;

  const BarcodeType(this.displayName, this.description);

  /// تحويل من enum إلى Barcode object من مكتبة barcode
  bc.Barcode toBarcodeObject() {
    switch (this) {
      case BarcodeType.ean13:
        return bc.Barcode.ean13();
      case BarcodeType.ean8:
        return bc.Barcode.ean8();
      case BarcodeType.upcA:
        return bc.Barcode.upcA();
      case BarcodeType.upcE:
        return bc.Barcode.upcE();
      case BarcodeType.code128:
        return bc.Barcode.code128();
      case BarcodeType.qrCode:
        return bc.Barcode.qrCode();
    }
  }

  /// الطول المطلوب للباركود (null = طول متغير)
  int? get requiredLength {
    switch (this) {
      case BarcodeType.ean13:
        return 13;
      case BarcodeType.ean8:
        return 8;
      case BarcodeType.upcA:
        return 12;
      case BarcodeType.upcE:
        return 8;
      case BarcodeType.code128:
      case BarcodeType.qrCode:
        return null; // طول متغير
    }
  }

  /// هل يدعم هذا النوع الأحرف؟
  bool get supportsAlpha {
    switch (this) {
      case BarcodeType.ean13:
      case BarcodeType.ean8:
      case BarcodeType.upcA:
      case BarcodeType.upcE:
        return false; // أرقام فقط
      case BarcodeType.code128:
      case BarcodeType.qrCode:
        return true;
    }
  }

  /// الحد الأدنى للطول
  int get minLength {
    switch (this) {
      case BarcodeType.ean13:
        return 13;
      case BarcodeType.ean8:
      case BarcodeType.upcE:
        return 8;
      case BarcodeType.upcA:
        return 12;
      case BarcodeType.code128:
        return 1;
      case BarcodeType.qrCode:
        return 1;
    }
  }

  /// الحد الأقصى للطول
  int get maxLength {
    switch (this) {
      case BarcodeType.ean13:
        return 13;
      case BarcodeType.ean8:
      case BarcodeType.upcE:
        return 8;
      case BarcodeType.upcA:
        return 12;
      case BarcodeType.code128:
        return 80;
      case BarcodeType.qrCode:
        return 4296; // حد QR Code
    }
  }
}
