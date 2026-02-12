import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/medicine_dto.dart';

/// Local data source for medicine dosing data.
///
/// Loads medicine data from the bundled JSON asset file.
class MedicineLocalDataSource {
  static const String _assetPath = 'assets/data/dosing/dosing_data.json';

  List<MedicineDto>? _cachedMedicines;

  /// Loads all medicines from the JSON asset file.
  ///
  /// Results are cached after first load for performance.
  /// Throws [Exception] if loading fails.
  Future<List<MedicineDto>> loadMedicines() async {
    if (_cachedMedicines != null) {
      return _cachedMedicines!;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      _cachedMedicines = jsonList
          .map((e) => MedicineDto.fromJson(e as Map<String, dynamic>))
          .toList();

      return _cachedMedicines!;
    } catch (e) {
      throw Exception('فشل في تحميل بيانات الأدوية: $e');
    }
  }

  /// Clears the cached data, forcing a reload on next access.
  void clearCache() {
    _cachedMedicines = null;
  }
}
