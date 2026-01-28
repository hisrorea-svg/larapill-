import 'package:equatable/equatable.dart';

/// كيان إعدادات الصيدلية في Domain Layer
///
/// هذا الكيان خالٍ تماماً من أي Flutter imports أو data layer dependencies
/// يستخدم Equatable للمقارنة بين الكيانات
class PharmacySettingsEntity extends Equatable {
  final int? id;
  final String nameAr;
  final String? nameEn;
  final String? licenseNumber;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? website;
  final String? address;
  final String? city;
  final String? taxNumber;
  final String? commercialRegistration;
  final String? logoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PharmacySettingsEntity({
    this.id,
    required this.nameAr,
    this.nameEn,
    this.licenseNumber,
    this.phone,
    this.mobile,
    this.email,
    this.website,
    this.address,
    this.city,
    this.taxNumber,
    this.commercialRegistration,
    this.logoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        licenseNumber,
        phone,
        mobile,
        email,
        website,
        address,
        city,
        taxNumber,
        commercialRegistration,
        logoPath,
        createdAt,
        updatedAt,
      ];

  /// إنشاء نسخة محدثة من الكيان
  PharmacySettingsEntity copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? licenseNumber,
    String? phone,
    String? mobile,
    String? email,
    String? website,
    String? address,
    String? city,
    String? taxNumber,
    String? commercialRegistration,
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PharmacySettingsEntity(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegistration:
          commercialRegistration ?? this.commercialRegistration,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// التحقق من أن البيانات الأساسية موجودة
  bool get hasBasicInfo => nameAr.isNotEmpty;

  /// الحصول على الاسم الكامل (عربي/إنجليزي)
  String getDisplayName({bool preferEnglish = false}) {
    if (preferEnglish && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return nameAr;
  }

  /// التحقق من وجود معلومات الاتصال
  bool get hasContactInfo =>
      phone != null && phone!.isNotEmpty ||
      mobile != null && mobile!.isNotEmpty ||
      email != null && email!.isNotEmpty;

  @override
  String toString() {
    return 'PharmacySettingsEntity{id: $id, nameAr: $nameAr, nameEn: $nameEn}';
  }
}
