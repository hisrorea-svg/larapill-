import '../entities/medicine.dart';

/// Repository interface for accessing medicine dosing data.
///
/// This interface belongs to the domain layer and defines the contract
/// that data layer implementations must fulfill.
abstract class MedicineRepository {
  /// Retrieves all medicines with their dosing information.
  ///
  /// Returns a list of [Medicine] entities.
  /// Throws an exception if data loading fails.
  Future<List<Medicine>> getAllMedicines();

  /// Searches medicines by name or category.
  ///
  /// [query] - Search term to filter medicines.
  /// Returns a filtered list of [Medicine] entities.
  Future<List<Medicine>> searchMedicines(String query);

  /// Finds the appropriate weight band for a given medicine and weight.
  ///
  /// [medicine] - The medicine to look up.
  /// [weightKg] - Patient weight in kilograms.
  /// Returns the matching [WeightBand] or null if not found.
  WeightBand? findWeightBand(Medicine medicine, double weightKg);
}
