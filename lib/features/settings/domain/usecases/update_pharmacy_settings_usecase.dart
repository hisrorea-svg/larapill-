import '../entities/pharmacy_settings_entity.dart';
import '../repositories/settings_repository.dart';
import '../failures/settings_failure.dart';

/// Parameters لتحديث إعدادات الصيدلية
class UpdatePharmacySettingsParams {
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

  const UpdatePharmacySettingsParams({
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
  });
}

/// Use Case لتحديث إعدادات الصيدلية
class UpdatePharmacySettingsUseCase {
  final SettingsRepository _repository;

  const UpdatePharmacySettingsUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, PharmacySettingsEntity>> call(
      UpdatePharmacySettingsParams params) async {
    // التحقق من البيانات الأساسية
    if (params.nameAr.trim().isEmpty) {
      return const Either.left(
          ValidationSettingsFailure('اسم الصيدلية (عربي) مطلوب'));
    }

    // جلب الإعدادات الحالية
    final currentSettingsResult = await _repository.getPharmacySettings();

    return currentSettingsResult.fold(
      (failure) => Either.left(failure),
      (currentSettings) async {
        final now = DateTime.now();

        // إنشاء أو تحديث الإعدادات
        final settings = currentSettings?.copyWith(
              nameAr: params.nameAr,
              nameEn: params.nameEn,
              licenseNumber: params.licenseNumber,
              phone: params.phone,
              mobile: params.mobile,
              email: params.email,
              website: params.website,
              address: params.address,
              city: params.city,
              taxNumber: params.taxNumber,
              commercialRegistration: params.commercialRegistration,
              logoPath: params.logoPath,
              updatedAt: now,
            ) ??
            PharmacySettingsEntity(
              nameAr: params.nameAr,
              nameEn: params.nameEn,
              licenseNumber: params.licenseNumber,
              phone: params.phone,
              mobile: params.mobile,
              email: params.email,
              website: params.website,
              address: params.address,
              city: params.city,
              taxNumber: params.taxNumber,
              commercialRegistration: params.commercialRegistration,
              logoPath: params.logoPath,
              createdAt: now,
              updatedAt: now,
            );

        return await _repository.savePharmacySettings(settings);
      },
    );
  }
}
