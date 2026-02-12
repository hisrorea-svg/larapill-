import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/medicine_local_datasource.dart';

/// Implementation of [MedicineRepository] using local JSON data.
class MedicineRepositoryImpl implements MedicineRepository {
  final MedicineLocalDataSource _localDataSource;

  MedicineRepositoryImpl(this._localDataSource);

  @override
  Future<List<Medicine>> getAllMedicines() async {
    final dtos = await _localDataSource.loadMedicines();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<Medicine>> searchMedicines(String query) async {
    final medicines = await getAllMedicines();

    if (query.isEmpty) {
      return medicines;
    }

    final lowerQuery = query.toLowerCase();
    return medicines.where((m) {
      return m.name.toLowerCase().contains(lowerQuery) ||
          m.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  WeightBand? findWeightBand(Medicine medicine, double weightKg) {
    for (final band in medicine.weightBands) {
      if (weightKg >= band.minKg && weightKg < band.maxKg) {
        return band;
      }
    }
    return null;
  }
}
