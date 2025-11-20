import 'package:flutter/material.dart';

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

enum ProductCategory {
  tablets('أقراص وكبسولات', 'Tablets & Capsules'),
  syrups('شرابات', 'Syrups'),
  injections('حقن', 'Injections'),
  creams('كريمات ومراهم', 'Creams & Ointments'),
  suppositories('تحاميل', 'Suppositories'),
  drops('قطرات', 'Drops'),
  sprays('بخاخات', 'Sprays'),
  medicalSupplies('مستلزمات طبية', 'Medical Supplies'),
  bandages('ضمادات وشاش', 'Bandages & Gauze'),
  syringes('محاقن', 'Syringes'),
  gloves('قفازات', 'Gloves'),
  masks('كمامات', 'Masks'),
  antiseptics('مطهرات', 'Antiseptics'),
  cosmetics('مستحضرات تجميل', 'Cosmetics');

  const ProductCategory(this.arabicName, this.englishName);

  final String arabicName;
  final String englishName;

  Color get color {
    switch (this) {
      case ProductCategory.tablets:
        return const Color(0xFF2196F3);
      case ProductCategory.syrups:
        return const Color(0xFF4CAF50);
      case ProductCategory.injections:
        return const Color(0xFF9C27B0);
      case ProductCategory.creams:
        return const Color(0xFFFF5722);
      case ProductCategory.suppositories:
        return const Color(0xFF607D8B);
      case ProductCategory.drops:
        return const Color(0xFFE91E63);
      case ProductCategory.sprays:
        return const Color(0xFF795548);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategory.tablets:
        return Icons.medication;
      case ProductCategory.syrups:
        return Icons.local_drink;
      case ProductCategory.injections:
        return Icons.medical_services;
      case ProductCategory.creams:
        return Icons.healing;
      case ProductCategory.suppositories:
        return Icons.medication;
      case ProductCategory.drops:
        return Icons.water_drop;
      case ProductCategory.sprays:
        return Icons.water_drop_outlined;
      default:
        return Icons.category;
    }
  }
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
