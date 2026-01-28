/// Parameters for adding a new product - Simplified Midgram-style
class AddProductParams {
  final String name;
  final String company;
  final String barcode;
  final int quantity; // إجمالي الوحدات
  final double price; // سعر بيع الوحدة
  final double cost; // سعر شراء الوحدة
  final DateTime expiryDate;

  // ═══ بيانات العلب (Midgram-style) ═══
  final int boxCount; // عدد العلب
  final int unitsPerBox; // التعبئة (وحدة/علبة)
  final double boxCost; // سعر شراء العلبة
  final double boxPrice; // سعر بيع العلبة

  const AddProductParams({
    required this.name,
    required this.company,
    required this.barcode,
    required this.quantity,
    required this.price,
    required this.cost,
    required this.expiryDate,
    required this.boxCount,
    required this.unitsPerBox,
    required this.boxCost,
    required this.boxPrice,
  });

  /// حساب إجمالي الوحدات تلقائياً
  int get totalUnits => boxCount * unitsPerBox;

  /// حساب سعر الوحدة من سعر العلبة
  double get unitPrice => unitsPerBox > 0 ? boxPrice / unitsPerBox : 0;
  double get unitCost => unitsPerBox > 0 ? boxCost / unitsPerBox : 0;
}
