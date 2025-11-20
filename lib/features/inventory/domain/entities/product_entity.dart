class ProductEntity {
  final int id;
  final String name;
  final String company;
  final String category;
  final String barcode;
  final int quantity;
  final double price;
  final double? costPrice; // ✅ nullable
  final DateTime? expiryDate;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.company,
    required this.category,
    required this.barcode,
    required this.quantity,
    required this.price,
    this.costPrice, // ✅ optional
    this.expiryDate,
  });
}
