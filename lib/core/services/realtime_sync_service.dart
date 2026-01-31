import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/network/presentation/providers/lan_providers.dart';
import '../../features/pos/presentation/providers/pos_providers.dart';
import '../../features/purchases/presentation/providers/daily_purchase_provider.dart';

/// خدمة التحديث التلقائي الذكي (Smart Polling)
/// تعمل كبديل للـ Realtime Websockets عندما لا يتوفر دعم من السيرفر
class RealtimeSyncService {
  final Ref ref;
  Timer? _timer;
  bool _isSyncing = false;
  bool _isDisposed = false;
  DateTime _lastCheck = DateTime.now().subtract(const Duration(minutes: 1));

  RealtimeSyncService(this.ref);

  /// بدء الخدمة
  void start() {
    if (_isDisposed) return; // لا تعمل إذا تم dispose

    stop(); // إيقاف أي مؤقت سابق

    // أفضل ممارسة: استخدام فاصل زمني 5 ثواني
    // هذا يوفر توازن بين الأداء وسرعة التحديث
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkUpdates());

    debugPrint('🚀 تم بدء خدمة المزامنة التلقائية (Smart Sync)');
  }

  /// إيقاف الخدمة
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// تنظيف الموارد عند الـ dispose
  void dispose() {
    _isDisposed = true;
    stop();
  }

  /// التحقق من وجود تحديثات
  Future<void> _checkUpdates() async {
    // تحقق من أنه لم يتم dispose
    if (_isDisposed) return;

    // 1. التحقق من تفعيل الوضع البعيد
    final useRemote = ref.read(shouldUseRemoteDatabaseProvider);
    if (!useRemote) return;

    // 2. منع التداخل (إذا كانت هناك عملية جارية)
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final productsProviderState = ref.read(posControllerProvider);

      // لا نقوم بالفحص إذا كان الـ Provider في حالة تحميل أصلاً
      if (productsProviderState.isLoading) {
        _isSyncing = false;
        return;
      }

      // 3. نطلب من السيرفر: هل حدث أي تغيير منذ آخر فحص؟
      // نستخدم صيغة ISO 8601 للتاريخ
      final since = _lastCheck.toIso8601String();

      // ملاحظة: نفترض هنا أن RemoteDatabaseService لديه دالة syncProducts
      // ولكن بما أننا لا نريد تعديل السيرفر، سنقوم بحيلة ذكية:
      // سنجلب فقط عدد قليل من المنتجات لاختبار الاتصال او نعتمد على syncProducts الموجودة
      // في هذه الحالة، سنستخدم syncProducts ونرى إذا عادت ببيانات

      // تلميح: في بيئة Laravel, من الأفضل وجود endpoint خفيف مثل /api/updates/check
      // ولكن بما أننا مقيدون، سنستخدم الموجود.

      // سنحدث التوقيت قبل الطلب بقليل لتجنب فجوات الوقت
      final nextCheck = DateTime.now();

      // بما أننا لا نملك endpoint مخصص للـ "Check Only"، سنقوم بعملية ذكية:
      // لن نقوم بجلب البيانات كاملة إلا إذا كنا متأكدين، لكن هنا سنعتمد على
      // أن المستخدم يريد "تحديث الصفحة".
      // لذلك، سنقوم بـ Invalidation كل فترة إذا اكتشفنا تغيير جوهري
      // أو ببساطة، سنقوم بعمل Invalidation دوري "ذكي".

      // ولكن، الحل الأفضل الذي طلبه المستخدم "بدون ريفريش":
      // سنقوم فقط بـ Invalidate للـ productsProvider
      // لكن لحظة! هذا سيسبب وميض (Loading) كل 5 ثواني! وهذا سيء جداً.
      // الحل "الاحترافي":
      // 1. نجلب البيانات في الخلفية.
      // 2. نقارن هل اختلف شيء؟
      // 3. إذا اختلف، نحدث الـ Provider.

      // بما أننا لا نستطيع بسهولة مقارنة قائمة كاملة (أداء سيء)،
      // سنلجأ لحل وسط:
      // سنعتمد على أن المزامنة يجب أن تكون "صامتة".
      // Riverpod FutureProvider لا يدعم التحديث الصامت بسهولة إلا إذا استخدمنا
      // ref.refresh أو invalidate وهذا يسبب Loading.

      // لذا، سنقوم بخدعة:
      // سنقوم بتحديث القيمة يدوياً إذا تغيرت، أو نستخدم StateNotifier بدلاً من FutureProvider
      // للمنتجات لتفادي الـ Loading state.
      // ولكن تغيير productsProvider الآن صعب.

      // ✅ الحل الفعلي المطبق الآن (Smart Invalidation):
      // سنقوم بعمل Invalidate فقط اذا مر وقت معين، أو سنعتمد على endpoint المزامنة.
      // بما اننا لا نملك endpoint "check"، سنقوم بالمزامنة الكاملة كل فترة أطول (مثلاً 10 ثواني)
      // إذا لم يكن لدينا خيار آخر.

      // **تعديل الخطة حسب طلب المستخدم (سريع وقوي)**:
      // المستخدم يريد تحديث فوري "الا اعمل ريفريش".
      // سأقوم بعمل refresh كل 5 ثواني، ولكن سأحاول جعله صامتاً.
      // كيف؟ بجعل الـ productsProvider يعيد القيمة القديمة أثناء التحميل (skipLoadingOnRefresh).
      // لكن FutureProvider لا يملك هذا الخيار مباشرة بالشكل القديم.

      // سأستخدم remoteDb directly لجلب التحديثات
      final remoteDb = ref.read(remoteDatabaseProvider);
      final updates = await remoteDb.syncProducts(since: since);

      if (updates.isNotEmpty) {
        debugPrint(
            '🔄 اكتشفنا ${updates.length} تحديثات، جاري تحديث الواجهة...');

        // وجدنا تحديثات!
        // نحدث التوقيت
        _lastCheck = nextCheck;

        // نحدث البروفايدرز
        ref.invalidate(posControllerProvider);
        ref.invalidate(dailyPurchaseNotifierProvider);
        // وأي شاشات أخرى
      } else {
        // لا توجد تحديثات، لا نفعل شيئاً (توفير موارد + عدم وميض)
        // Only update time if successful check
        _lastCheck = nextCheck;
      }
    } catch (e) {
      debugPrint('⚠️ فشل الفحص التلقائي: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(ref);

  // تنظيف تلقائي عند dispose
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
