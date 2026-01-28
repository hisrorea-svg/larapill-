import 'package:flutter/foundation.dart';

import '../../domain/entities/pharmacy_settings_entity.dart';

/// DTO (Data Transfer Object) for Pharmacy Settings.
///
/// Responsible for:
/// - Serialization/deserialization (Map)
/// - Conversion to domain entity
/// - Immutability and copyWith pattern
@immutable
class PharmacySettingsModel {
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PharmacySettingsModel({
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
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Map (database row).
  factory PharmacySettingsModel.fromMap(Map<String, dynamic> map) {
    return PharmacySettingsModel(
      id: map['id'] as int?,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String?,
      licenseNumber: map['license_number'] as String?,
      phone: map['phone'] as String?,
      mobile: map['mobile'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      taxNumber: map['tax_number'] as String?,
      commercialRegistration: map['commercial_registration'] as String?,
      logoPath: map['logo_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'license_number': licenseNumber,
      'phone': phone,
      'mobile': mobile,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'tax_number': taxNumber,
      'commercial_registration': commercialRegistration,
      'logo_path': logoPath,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity.
  PharmacySettingsEntity toEntity() {
    return PharmacySettingsEntity(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      licenseNumber: licenseNumber,
      phone: phone,
      mobile: mobile,
      email: email,
      website: website,
      address: address,
      city: city,
      taxNumber: taxNumber,
      commercialRegistration: commercialRegistration,
      logoPath: logoPath,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create model from entity.
  factory PharmacySettingsModel.fromEntity(PharmacySettingsEntity entity) {
    return PharmacySettingsModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      licenseNumber: entity.licenseNumber,
      phone: entity.phone,
      mobile: entity.mobile,
      email: entity.email,
      website: entity.website,
      address: entity.address,
      city: entity.city,
      taxNumber: entity.taxNumber,
      commercialRegistration: entity.commercialRegistration,
      logoPath: entity.logoPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with optional field replacements.
  PharmacySettingsModel copyWith({
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
    return PharmacySettingsModel(
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

  @override
  String toString() {
    return 'PharmacySettingsModel('
        'id: $id, '
        'nameAr: $nameAr, '
        'nameEn: $nameEn, '
        'phone: $phone, '
        'email: $email)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PharmacySettingsModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nameAr == other.nameAr &&
          nameEn == other.nameEn &&
          licenseNumber == other.licenseNumber &&
          phone == other.phone &&
          mobile == other.mobile &&
          email == other.email &&
          website == other.website &&
          address == other.address &&
          city == other.city &&
          taxNumber == other.taxNumber &&
          commercialRegistration == other.commercialRegistration &&
          logoPath == other.logoPath &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      nameAr.hashCode ^
      nameEn.hashCode ^
      licenseNumber.hashCode ^
      phone.hashCode ^
      mobile.hashCode ^
      email.hashCode ^
      website.hashCode ^
      address.hashCode ^
      city.hashCode ^
      taxNumber.hashCode ^
      commercialRegistration.hashCode ^
      logoPath.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
