enum MedicineUnit {
  // للأقراص والكبسولات
  strip('شريط', 'Strip'),
  box('علبة', 'Box'),
  carton('كرتون', 'Carton'),

  // للسوائل والشرابات
  bottle('قنينة', 'Bottle'),
  vial('قارورة', 'Vial'),

  // للحقن
  ampoule('أمبولة', 'Ampoule'),
  injection('حقنة', 'Injection'),

  // للكريمات والمراهم
  tube('أنبوب', 'Tube'),
  jar('علبة كريم', 'Jar'),

  // للتحاميل
  suppository('تحميلة', 'Suppository'),

  // للبودرة والأكياس
  sachet('كيس', 'Sachet'),
  packet('ظرف', 'Packet'),

  // للمستلزمات الطبية
  piece('قطعة', 'Piece'),
  roll('رول', 'Roll'),
  pack('حزمة', 'Pack'),

  // للقطرات والبخاخات
  drops('قطرة', 'Drops'),
  spray('بخاخ', 'Spray'),
  inhaler('بخاخ استنشاق', 'Inhaler');

  const MedicineUnit(this.arabicName, this.englishName);

  final String arabicName;
  final String englishName;
}

class UnitInfo {
  final double sellingPrice;
  final double costPrice;
  final double conversionToBase;
  final String description;
  final int? quantity;

  const UnitInfo({
    required this.sellingPrice,
    required this.costPrice,
    required this.conversionToBase,
    required this.description,
    this.quantity,
  });

  UnitInfo copyWith({
    double? sellingPrice,
    double? costPrice,
    double? conversionToBase,
    String? description,
    int? quantity,
  }) {
    return UnitInfo(
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      conversionToBase: conversionToBase ?? this.conversionToBase,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'conversionToBase': conversionToBase,
      'description': description,
      'quantity': quantity,
    };
  }

  factory UnitInfo.fromMap(Map<String, dynamic> map) {
    return UnitInfo(
      sellingPrice: map['sellingPrice']?.toDouble() ?? 0.0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      conversionToBase: map['conversionToBase']?.toDouble() ?? 1.0,
      description: map['description'] ?? '',
      quantity: map['quantity']?.toInt(),
    );
  }

  @override
  String toString() {
    return 'UnitInfo(sellingPrice: $sellingPrice, costPrice: $costPrice, conversionToBase: $conversionToBase, description: $description, quantity: $quantity)';
  }
}
