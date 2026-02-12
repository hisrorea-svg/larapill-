import '../../domain/entities/medicine.dart';

/// Data Transfer Object for Medicine from JSON.
///
/// This model handles JSON parsing and converts to domain entities.
class MedicineDto {
  final String name;
  final String category;
  final String indication;
  final String standardDose;
  final String route;
  final List<WeightBandDto> weightBands;

  const MedicineDto({
    required this.name,
    required this.category,
    required this.indication,
    required this.standardDose,
    required this.route,
    required this.weightBands,
  });

  /// Creates a [MedicineDto] from JSON map.
  factory MedicineDto.fromJson(Map<String, dynamic> json) {
    return MedicineDto(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      indication: json['indication'] as String? ?? '',
      standardDose: json['standard_dose'] as String? ?? '',
      route: json['route'] as String? ?? '',
      weightBands: (json['weight_bands'] as List<dynamic>?)
              ?.map((e) => WeightBandDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this DTO to a domain [Medicine] entity.
  Medicine toEntity() {
    return Medicine(
      name: name,
      category: category,
      indication: indication,
      standardDose: standardDose,
      route: route,
      weightBands: weightBands.map((wb) => wb.toEntity()).toList(),
    );
  }
}

/// Data Transfer Object for WeightBand from JSON.
class WeightBandDto {
  final double minKg;
  final double maxKg;
  final dynamic doseMg;
  final List<FormulationDto> formulations;

  const WeightBandDto({
    required this.minKg,
    required this.maxKg,
    required this.doseMg,
    required this.formulations,
  });

  factory WeightBandDto.fromJson(Map<String, dynamic> json) {
    return WeightBandDto(
      minKg: (json['min_kg'] as num?)?.toDouble() ?? 0.0,
      maxKg: (json['max_kg'] as num?)?.toDouble() ?? 0.0,
      doseMg: json['dose_mg'],
      formulations: (json['formulations'] as List<dynamic>?)
              ?.map((e) => FormulationDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  WeightBand toEntity() {
    return WeightBand(
      minKg: minKg,
      maxKg: maxKg,
      doseMg: doseMg,
      formulations: formulations.map((f) => f.toEntity()).toList(),
    );
  }
}

/// Data Transfer Object for Formulation from JSON.
class FormulationDto {
  final String type;
  final String strength;
  final String amount;

  const FormulationDto({
    required this.type,
    required this.strength,
    required this.amount,
  });

  factory FormulationDto.fromJson(Map<String, dynamic> json) {
    return FormulationDto(
      type: json['type'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }

  Formulation toEntity() {
    return Formulation(
      type: type,
      strength: strength,
      amount: amount,
    );
  }
}
