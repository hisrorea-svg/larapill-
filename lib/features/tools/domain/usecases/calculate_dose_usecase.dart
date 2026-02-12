import '../entities/medicine.dart';
import '../repositories/medicine_repository.dart';

/// Use case for calculating pediatric dosing based on weight or age.
///
/// This use case encapsulates the business logic for dose calculation,
/// including age-to-weight estimation using the APLS formula.
class CalculateDoseUseCase {
  final MedicineRepository _repository;

  const CalculateDoseUseCase(this._repository);

  /// Calculates the appropriate dose for a patient.
  ///
  /// [medicine] - The medicine to calculate dose for.
  /// [weightKg] - Patient weight in kilograms (optional if ageYears provided).
  /// [ageYears] - Patient age in years (used to estimate weight if weightKg not provided).
  ///
  /// Returns a [DoseResult] containing the calculated dose and weight band.
  DoseResult calculate({
    required Medicine medicine,
    double? weightKg,
    double? ageYears,
  }) {
    if (weightKg == null && ageYears == null) {
      return DoseResult.error('يجب إدخال الوزن أو العمر');
    }

    final double effectiveWeight;
    double? estimatedWeight;

    if (weightKg != null) {
      effectiveWeight = weightKg;
    } else {
      estimatedWeight = _estimateWeightFromAge(ageYears!);
      effectiveWeight = estimatedWeight;
    }

    final weightBand = _repository.findWeightBand(medicine, effectiveWeight);

    if (weightBand == null) {
      return DoseResult.error('لم يتم العثور على جرعة مناسبة لهذا الوزن');
    }

    return DoseResult.success(
      weightBand: weightBand,
      estimatedWeight: estimatedWeight,
    );
  }

  /// Estimates weight from age using APLS (Advanced Paediatric Life Support) formula.
  ///
  /// - Infants (<1 year): (age in months + 9) / 2
  /// - 1-5 years: (age × 2) + 8
  /// - 6-12 years: (age × 3) + 7
  /// - >12 years: 50 + (age - 12) × 2
  double _estimateWeightFromAge(double ageInYears) {
    if (ageInYears < 1) {
      return (ageInYears * 12 + 9) / 2;
    } else if (ageInYears <= 5) {
      return (ageInYears * 2) + 8;
    } else if (ageInYears <= 12) {
      return (ageInYears * 3) + 7;
    } else {
      return 50 + (ageInYears - 12) * 2;
    }
  }
}

/// Result of a dose calculation.
class DoseResult {
  final bool isSuccess;
  final WeightBand? weightBand;
  final double? estimatedWeight;
  final String? errorMessage;

  const DoseResult._({
    required this.isSuccess,
    this.weightBand,
    this.estimatedWeight,
    this.errorMessage,
  });

  factory DoseResult.success({
    required WeightBand weightBand,
    double? estimatedWeight,
  }) {
    return DoseResult._(
      isSuccess: true,
      weightBand: weightBand,
      estimatedWeight: estimatedWeight,
    );
  }

  factory DoseResult.error(String message) {
    return DoseResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
