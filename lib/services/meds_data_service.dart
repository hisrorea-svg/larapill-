import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class MedsDataService {
  static List<Map<String, dynamic>> _medsCache = [];
  static bool _isLoaded = false;

  /// تحميل بيانات الأدوية من meds.json
  static Future<void> loadMeds() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/meds.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);

      _medsCache = List<Map<String, dynamic>>.from(
          jsonData.map((item) => Map<String, dynamic>.from(item as Map)));

      _isLoaded = true;
      developer.log('✅ تم تحميل ${_medsCache.length} دواء من meds.json',
          name: 'MedsService');
    } catch (e) {
      developer.log('❌ خطأ في تحميل meds.json: $e', name: 'MedsService');
    }
  }

  /// البحث عن الأدوية (بحث فوري)
  static List<Map<String, dynamic>> searchMeds(String query) {
    if (query.isEmpty || _medsCache.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return _medsCache
        .where((med) {
          final name = (med['name'] ?? '').toString().toLowerCase();
          final scientificName =
              (med['scientificName'] ?? '').toString().toLowerCase();
          final manufacturer =
              (med['manufacturer'] ?? '').toString().toLowerCase();

          return name.contains(lowerQuery) ||
              scientificName.contains(lowerQuery) ||
              manufacturer.contains(lowerQuery);
        })
        .take(10)
        .toList();
  }
}
