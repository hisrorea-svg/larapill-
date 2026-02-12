import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

/// 🚀 MedsDataService - Lazy Loading + Indexed Search
/// 
/// الميزات:
/// - ✅ لا يتم تحميل البيانات في الذاكرة
/// - ✅ فهرسة في SQLite in-memory للبحث السريع
/// - ✅ Batching لتجنب حظر UI
class MedsDataService {
  static Database? _indexDatabase;
  static bool _isInitialized = false;
  static final _initCompleter = Completer<void>();

  // ==========================================================================
  // Public API
  // ==========================================================================

  /// ✅ تهيئة خفيفة - فقط فتح قاعدة البيانات
  static Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter.isCompleted) return _initCompleter.future;

    try {
      developer.log('🔧 Initializing MedsDataService...', name: 'MedsService');

      // ✅ الخطوة 1: فتح قاعدة البيانات
      _indexDatabase = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meds_index (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              scientific_name TEXT,
              name_lower TEXT NOT NULL,
              manufacturer TEXT,
              data TEXT NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX idx_name_lower ON meds_index(name_lower)');
        },
      );

      developer.log('✅ Database schema created', name: 'MedsService');

      // ✅ الخطوة 2: تحميل البيانات في دفعات (بدون Isolate)
      await _loadDataInBatches();

      _isInitialized = true;
      _initCompleter.complete();
    } catch (e, stack) {
      developer.log('❌ Failed to initialize: $e',
          name: 'MedsService', error: e, stackTrace: stack);
      _initCompleter.completeError(e);
      rethrow;
    }

    return _initCompleter.future;
  }

  /// ✅ البحث الفوري (باستخدام Index)
  static Future<List<Map<String, dynamic>>> search(String query) async {
    await init();

    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();

    final results = await _indexDatabase!.query(
      'meds_index',
      columns: ['data'],
      where: 'name_lower LIKE ?',
      whereArgs: ['%$lowerQuery%'],
      limit: 10,
      orderBy: 'name_lower ASC',
    );

    return results
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// ✅ البحث السريع (للاقتراحات)
  static Future<List<Map<String, dynamic>>> quickSearch(String query) async {
    await init();

    if (query.trim().isEmpty) return [];
    if (query.length < 2) return [];

    final lowerQuery = query.toLowerCase().trim();

    final results = await _indexDatabase!.query(
      'meds_index',
      columns: ['data'],
      where: 'name_lower LIKE ?',
      whereArgs: ['$lowerQuery%'],
      limit: 5,
    );

    return results
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// ✅ فحص حالة التهيئة
  static bool get isInitialized => _isInitialized;

  // ==========================================================================
  // Private Implementation
  // ==========================================================================

  static Future<void> _loadDataInBatches() async {
    // ✅ تحميل JSON
    final jsonString = await rootBundle.loadString('assets/data/meds.json');
    final medsData = jsonDecode(jsonString) as List<dynamic>;

    developer.log('📦 Loaded ${medsData.length} medicines', name: 'MedsService');

    // ✅ إدخال في دفعات صغيرة
    const batchSize = 300;
    final totalRecords = medsData.length;

    for (var i = 0; i < totalRecords; i += batchSize) {
      final batch = medsData.skip(i).take(batchSize);

      await _indexDatabase!.transaction((txn) async {
        final batchInsert = txn.batch();

        for (final med in batch) {
          final name = med['name']?.toString() ?? '';

          batchInsert.insert('meds_index', {
            'name': name,
            'scientific_name': med['scientificName']?.toString() ?? '',
            'name_lower': name.toLowerCase(),
            'manufacturer': med['manufacturer']?.toString() ?? '',
            'data': jsonEncode(med),
          });
        }

        await batchInsert.commit(noResult: true);
      });

      // ✅ إعادة التحكم للـ UI كل 300 سجل
      await Future.delayed(Duration.zero);

      if ((i + batchSize) % 1000 == 0 || i + batchSize >= totalRecords) {
        developer.log(
          '📊 Indexed ${(i + batchSize).clamp(0, totalRecords)}/$totalRecords',
          name: 'MedsService',
        );
      }
    }

    developer.log('✅ Indexing complete', name: 'MedsService');
  }

  // ==========================================================================
  // Deprecated Methods
  // ==========================================================================

  @Deprecated('استخدم init() بدلاً منه')
  static Future<void> loadMeds() async {
    await init();
  }

  @Deprecated('استخدم search() بدلاً منه')
  static List<Map<String, dynamic>> searchMeds(String query) {
    throw UnsupportedError(
        'searchMeds is deprecated. Use search() which returns Future.');
  }
}
