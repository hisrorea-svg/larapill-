/// Domain entity representing a medicine with dosing information.
///
/// This entity is independent of data sources and contains only
/// the business-relevant properties for dosing calculations.
class Medicine {
  /// Unique name identifier for the medicine.
  final String name;

  /// Therapeutic category (e.g., Antibiotic, Antihistamine).
  final String category;

  /// Clinical indications for use.
  final String indication;

  /// Standard dosing description (e.g., "10 mg/kg/dose").
  final String standardDose;

  /// Administration route (e.g., Oral, IV, IM).
  final String route;

  /// Weight-based dosing bands for pediatric patients.
  final List<WeightBand> weightBands;

  const Medicine({
    required this.name,
    required this.category,
    required this.indication,
    required this.standardDose,
    required this.route,
    required this.weightBands,
  });
}

/// Weight band defining dosing for a specific weight range.
class WeightBand {
  /// Minimum weight in kg (inclusive).
  final double minKg;

  /// Maximum weight in kg (exclusive).
  final double maxKg;

  /// Dose in mg for this weight range.
  final dynamic doseMg;

  /// Available pharmaceutical formulations for this dose.
  final List<Formulation> formulations;

  const WeightBand({
    required this.minKg,
    required this.maxKg,
    required this.doseMg,
    required this.formulations,
  });
}

/// Pharmaceutical formulation with strength and amount.
class Formulation {
  /// Type of formulation (e.g., Syrup, Tablet, Capsule).
  final String type;

  /// Strength specification (e.g., "250 mg/5ml").
  final String strength;

  /// Amount to administer (e.g., "5 mL", "1 tablet").
  final String amount;

  const Formulation({
    required this.type,
    required this.strength,
    required this.amount,
  });
}
