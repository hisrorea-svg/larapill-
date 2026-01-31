/// 🧠 خدمة الذكاء الاصطناعي لتحليل المنتجات تلقائياً
/// تحلل اسم المنتج وتقترح الوحدات والأسعار بذكاء
class ProductIntelligenceService {
  /// كلمات مفتاحية تدل على أن المنتج قابل للتقسيم
  static const _divisibleKeywords = [
    'tab',
    'tablet',
    'cap',
    'capsule',
    'strip',
    'ampoule',
    'amp',
    'vial',
    'sachet',
    'suppository',
    'supp',
  ];

  /// كلمات تدل على وحدات غير قابلة للتقسيم
  static const _indivisibleKeywords = [
    'syrup',
    'bottle',
    'cream',
    'gel',
    'ointment',
    'drops',
    'spray',
    'inhaler',
    'tube',
  ];

  /// 🔍 تحليل اسم المنتج وتحديد هل قابل للتقسيم
  static ProductAnalysis analyzeProductName(String productName) {
    final nameLower = productName.toLowerCase();

    // ✅ تحليل 1: البحث عن كلمات مفتاحية
    bool isDivisible = false;
    String? detectedUnit;
    int? detectedQuantity;

    // فحص الكلمات غير القابلة للتقسيم أولاً
    for (final keyword in _indivisibleKeywords) {
      if (nameLower.contains(keyword)) {
        return ProductAnalysis(
          isDivisible: false,
          suggestedBaseUnit: _getSuggestedUnit(keyword),
          needsHigherUnit: false,
          detectedQuantity: null,
          confidence: 0.9,
        );
      }
    }

    // فحص الكلمات القابلة للتقسيم
    for (final keyword in _divisibleKeywords) {
      if (nameLower.contains(keyword)) {
        isDivisible = true;
        detectedUnit = keyword;
        break;
      }
    }

    // ✅ تحليل 2: البحث عن أرقام (مثل "10 tab" أو "20mg/2ml")
    final numberPattern =
        RegExp(r'(\d+)\s*(tab|cap|strip|amp|ml)', caseSensitive: false);
    final match = numberPattern.firstMatch(nameLower);

    if (match != null) {
      isDivisible = true;
      detectedQuantity = int.tryParse(match.group(1) ?? '');
      detectedUnit ??= match.group(2);
    }

    // ✅ تحليل 3: فحص العلامات التجارية المعروفة
    if (_isKnownBoxedProduct(nameLower)) {
      isDivisible = true;
    }

    return ProductAnalysis(
      isDivisible: isDivisible,
      suggestedBaseUnit:
          detectedUnit != null ? _getSuggestedUnit(detectedUnit) : 'strip',
      needsHigherUnit: isDivisible,
      detectedQuantity: detectedQuantity,
      confidence: isDivisible ? 0.85 : 0.5,
    );
  }

  /// 🎯 اقتراح الوحدة الأساسية بناءً على الكلمة المفتاحية
  static String _getSuggestedUnit(String keyword) {
    if (keyword.contains('tab') || keyword.contains('cap')) return 'strip';
    if (keyword.contains('amp')) return 'ampoule';
    if (keyword.contains('vial')) return 'vial';
    if (keyword.contains('syrup') || keyword.contains('bottle')) {
      return 'bottle';
    }
    if (keyword.contains('cream') ||
        keyword.contains('gel') ||
        keyword.contains('ointment')) {
      return 'tube';
    }
    if (keyword.contains('drops')) return 'drops';
    if (keyword.contains('spray') || keyword.contains('inhaler')) {
      return 'spray';
    }
    if (keyword.contains('sachet')) return 'sachet';
    if (keyword.contains('supp')) return 'suppository';

    return 'strip'; // الافتراضي
  }

  /// 📦 فحص إذا المنتج من العلامات المعروفة التي تأتي بعلب
  static bool _isKnownBoxedProduct(String name) {
    // يمكن توسيع هذه القائمة
    final boxedBrands = ['augmentin', 'amoxil', 'flagyl', 'panadol'];
    return boxedBrands.any((brand) => name.contains(brand));
  }

  /// 💰 حساب سعر الوحدة الأعلى تلقائياً
  static double calculateHigherUnitPrice({
    required double basePrice,
    required int unitsPerHigherUnit,
  }) {
    return basePrice * unitsPerHigherUnit;
  }

  /// 💰 حساب سعر الوحدة الأساسية من سعر العلبة
  static double calculateBasePriceFromBox({
    required double boxPrice,
    required int unitsPerBox,
  }) {
    return boxPrice / unitsPerBox;
  }

  /// 🔢 اقتراح معامل التحويل الافتراضي
  static int suggestConversionFactor(String baseUnit) {
    // معاملات شائعة حسب الوحدة
    switch (baseUnit) {
      case 'strip':
        return 10; // عادة 10 أشرطة في العلبة
      case 'ampoule':
      case 'vial':
        return 5; // عادة 5 أمبولات في العلبة
      case 'sachet':
        return 10;
      case 'suppository':
        return 6;
      default:
        return 1;
    }
  }
}

/// 📊 نتيجة تحليل المنتج
class ProductAnalysis {
  final bool isDivisible;
  final String suggestedBaseUnit;
  final bool needsHigherUnit;
  final int? detectedQuantity;
  final double confidence; // 0.0 - 1.0

  ProductAnalysis({
    required this.isDivisible,
    required this.suggestedBaseUnit,
    required this.needsHigherUnit,
    this.detectedQuantity,
    required this.confidence,
  });

  @override
  String toString() {
    return 'ProductAnalysis(isDivisible: $isDivisible, unit: $suggestedBaseUnit, '
        'needsHigher: $needsHigherUnit, qty: $detectedQuantity, '
        'confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}
