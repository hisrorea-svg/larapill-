/// حاسبة التكاليف للمشتريات
///
/// تحتوي على المنطق المحاسبي لحساب:
/// - التكلفة لكل وحدة مع البونص
/// - متوسط التكلفة المرجح
/// - هامش الربح
class CostCalculator {
  const CostCalculator._();

  /// حساب التكلفة لكل وحدة (مع البونص)
  ///
  /// [purchasePrice] سعر شراء الكمية الأساسية
  /// [quantity] الكمية الأساسية المشتراة
  /// [bonus] كمية البونص المجانية
  ///
  /// مثال: 10 قطع بـ 1000 + 2 بونص = 1000/12 = 83.33 للوحدة
  static double calculateCostPerUnit({
    required double purchasePrice,
    required double quantity,
    required double bonus,
  }) {
    if (purchasePrice <= 0 || quantity <= 0) return 0;

    final totalUnits = quantity + bonus;
    if (totalUnits <= 0) return 0;

    return purchasePrice / totalUnits;
  }

  /// حساب إجمالي قيمة الشراء
  static double calculateTotal({
    required double unitPrice,
    required double quantity,
  }) {
    return unitPrice * quantity;
  }

  /// حساب نسبة البونص
  static double calculateBonusPercent({
    required double quantity,
    required double bonus,
  }) {
    if (quantity <= 0) return 0;
    return (bonus / quantity) * 100;
  }

  /// حساب توفير البونص بالقيمة
  static double calculateBonusSavings({
    required double costPerUnit,
    required double bonus,
  }) {
    return costPerUnit * bonus;
  }

  /// مقارنة السعر الجديد بالسعر القديم
  ///
  /// ترجع نسبة التغير: موجب = ارتفاع، سالب = انخفاض
  static double calculatePriceChangePercent({
    required double oldPrice,
    required double newPrice,
  }) {
    if (oldPrice <= 0) return 0;
    return ((newPrice - oldPrice) / oldPrice) * 100;
  }

  /// هل هناك تغير ملحوظ في السعر؟
  static bool hasSignificantPriceChange({
    required double oldPrice,
    required double newPrice,
    double threshold = 5.0, // نسبة التغير الملحوظة %
  }) {
    if (oldPrice <= 0) return false;
    final change = ((newPrice - oldPrice) / oldPrice).abs() * 100;
    return change >= threshold;
  }

  /// حساب متوسط التكلفة المرجح (WAC)
  ///
  /// يستخدم عند إضافة مخزون جديد لمنتج موجود
  static double calculateWeightedAverageCost({
    required double currentStock,
    required double currentCost,
    required double newQuantity,
    required double newCost,
  }) {
    final totalQuantity = currentStock + newQuantity;
    if (totalQuantity <= 0) return newCost;

    final totalValue = (currentStock * currentCost) + (newQuantity * newCost);
    return totalValue / totalQuantity;
  }

  /// حساب هامش الربح
  static double calculateProfitMargin({
    required double costPrice,
    required double sellingPrice,
  }) {
    if (sellingPrice <= 0) return 0;
    return ((sellingPrice - costPrice) / sellingPrice) * 100;
  }

  /// حساب السعر المقترح للربح المستهدف
  static double calculateSuggestedPrice({
    required double costPrice,
    required double targetMarginPercent,
  }) {
    if (costPrice <= 0 || targetMarginPercent >= 100) return 0;
    return costPrice / (1 - (targetMarginPercent / 100));
  }
}

/// نتيجة حساب التكلفة
class CostCalculationResult {
  final double costPerUnit;
  final double totalAmount;
  final double bonusPercent;
  final double bonusSavings;
  final double? priceChangePercent;
  final bool hasPriceWarning;

  const CostCalculationResult({
    required this.costPerUnit,
    required this.totalAmount,
    required this.bonusPercent,
    required this.bonusSavings,
    this.priceChangePercent,
    this.hasPriceWarning = false,
  });

  factory CostCalculationResult.calculate({
    required double purchasePrice,
    required double quantity,
    required double bonus,
    double? oldCost,
    double priceChangeThreshold = 5.0,
  }) {
    final costPerUnit = CostCalculator.calculateCostPerUnit(
      purchasePrice: purchasePrice,
      quantity: quantity,
      bonus: bonus,
    );

    final totalAmount = CostCalculator.calculateTotal(
      unitPrice: purchasePrice / quantity,
      quantity: quantity,
    );

    final bonusPercent = CostCalculator.calculateBonusPercent(
      quantity: quantity,
      bonus: bonus,
    );

    final bonusSavings = CostCalculator.calculateBonusSavings(
      costPerUnit: costPerUnit,
      bonus: bonus,
    );

    double? priceChange;
    bool hasWarning = false;
    if (oldCost != null && oldCost > 0) {
      priceChange = CostCalculator.calculatePriceChangePercent(
        oldPrice: oldCost,
        newPrice: costPerUnit,
      );
      hasWarning = CostCalculator.hasSignificantPriceChange(
        oldPrice: oldCost,
        newPrice: costPerUnit,
        threshold: priceChangeThreshold,
      );
    }

    return CostCalculationResult(
      costPerUnit: costPerUnit,
      totalAmount: totalAmount,
      bonusPercent: bonusPercent,
      bonusSavings: bonusSavings,
      priceChangePercent: priceChange,
      hasPriceWarning: hasWarning,
    );
  }
}
