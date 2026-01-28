import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../models/product.dart';
import '../../../models/medicine_unit.dart';
import '../../../core/network/sync_aware_dao.dart';
import '../../returns/widgets/return_form_dialog.dart';
import '../domain/entities/sale.dart';
import '../widgets/checkout_panel.dart';
import '../providers/pos_providers.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Product> _searchResults = [];
  bool _isSearching = false;

  // ✨ Debounce Timer للماسح الضوئي
  Timer? _debounce;
  // ✨ تتبع العنصر المختار بالكيبورد
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    _searchController.addListener(_onSearchChanged);
    // ❌ تمت إزالة FocusListener - كان يسبب مشاكل الماوس
  }

  // ✨ معالجة أحداث الكيبورد (الأسهم و Escape)
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_searchResults.isNotEmpty &&
            _selectedIndex < _searchResults.length - 1) {
          setState(() => _selectedIndex++);
          _overlayEntry?.markNeedsBuild();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_searchResults.isNotEmpty && _selectedIndex > 0) {
          setState(() => _selectedIndex--);
          _overlayEntry?.markNeedsBuild();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideOverlay();
        _searchController.clear();
      }
    }
  }

  void _onSearchChanged() {
    // ✨ Debounce: إلغاء المؤقت السابق وإنشاء جديد
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _hideOverlay();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // تأخير 300ms للانتظار حتى انتهاء الكتابة أو الماسح
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        _performLiveSearch(query);
      } else {
        _hideOverlay();
      }
    });
  }

  void _performLiveSearch(String query) {
    setState(() => _isSearching = true);

    // استخدام البيانات المحملة مسبقاً
    final productsAsync = ref.read(posControllerProvider);

    if (productsAsync.hasValue) {
      final allProducts = productsAsync.value!;
      final results = allProducts
          .where((p) {
            final name = p.name.toLowerCase();
            final scientific = p.scientificName?.toLowerCase() ?? '';
            final barcode = p.barcode;
            final q = query.toLowerCase();
            return name.contains(q) ||
                scientific.contains(q) ||
                barcode.contains(q);
          })
          .take(8)
          .toList();

      setState(() {
        _searchResults = results;
        _selectedIndex = 0; // ✨ إعادة تعيين المؤشر لأول عنصر
        _isSearching = false;
      });

      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } else {
      // البيانات لم تحمل بعد
      setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _debounce?.cancel(); // ✨ إلغاء المؤقت
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        // نفس عرض قسم السلة (2/3 من الشاشة)
        final screenWidth = MediaQuery.of(context).size.width;
        final searchWidth =
            (screenWidth - 40) * 2 / 3 - 10; // نفس عرض البحث تقريباً

        return Stack(
          children: [
            // طبقة شفافة للإغلاق عند النقر خارج القائمة
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // القائمة المنسدلة
            Positioned(
              width: searchWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isSearching
                        ? _buildShimmerLoading()
                        : _buildSearchResultsList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        height: 60,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'لا توجد نتائج',
          style: GoogleFonts.tajawal(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (_, index) {
        final product = _searchResults[index];
        return _buildSearchResultItem(product, index); // ✨ تمرير index
      },
    );
  }

  // ✨ عنصر نتيجة بحث مع دعم التحديد والـ Hover
  Widget _buildSearchResultItem(Product product, int index) {
    final price = product.unitInfo[product.baseUnit]?.sellingPrice ?? 0;
    final isSelected = index == _selectedIndex; // هل هذا العنصر مختار؟

    return MouseRegion(
      onEnter: (_) {
        setState(() => _selectedIndex = index);
        _overlayEntry?.markNeedsBuild();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectProduct(product),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // أيقونة المنتج
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // معلومات المنتج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المخزون: ${product.currentStock.toInt()} | ${product.barcode}',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // السعر
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${price.toInt()} د.ع',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✨ دالة موحدة لإضافة المنتج
  void _selectProduct(Product product) {
    _addToCartDirectly(product, product.baseUnit);
    _hideOverlay();
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  void _showReturnDialog() {
    showDialog(
      context: context,
      builder: (context) => ReturnFormDialog(
        onReturnCreated: () {
          // تحديث البيانات بعد إنشاء المرتجع
          ref.read(posControllerProvider.notifier).refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // ✅ تحميل المنتجات عند فتح الشاشة
            final productsState = ref.watch(posControllerProvider);

            // إظهار رسالة تحميل إذا البيانات لم تحمل بعد
            if (productsState.isLoading && !productsState.hasValue) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل المنتجات...'),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: isWide
                      ? _buildHorizontalLayout()
                      : _buildVerticalLayout(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 🔍 شريط البحث الموحد
  Widget _buildSearchBar() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? AppColors.primary
                : AppColors.border,
            width: _searchFocusNode.hasFocus ? 2 : 1,
          ),
          boxShadow: _searchFocusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // أيقونة البحث / الباركود
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(13)),
              ),
              child: _isSearching
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
            ),

            const SizedBox(width: 8),

            // حقل البحث مع دعم الكيبورد
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'امسح الباركود أو اكتب اسم المنتج...',
                    hintStyle: GoogleFonts.tajawal(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: _handleSearchSubmit,
                ),
              ),
            ),

            // زر المسح
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.requestFocus();
                  setState(() {});
                },
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      const Icon(Icons.close, size: 16, color: AppColors.error),
                ),
                tooltip: 'مسح',
              ),

            // الفاصل
            Container(
              width: 1,
              height: 32,
              color: AppColors.border,
            ),

            // زر الإرجاع
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showReturnDialog(),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(13)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 56,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_return_outlined,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مرتجع',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔄 التخطيط الأفقي (Desktop)
  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🛒 السلة مع البحث فوقها
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // 🔍 البحث فوق السلة فقط
              _buildSearchBar(),
              const SizedBox(height: 12),
              // السلة
              Expanded(child: _buildCartSection()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 💳 Checkout - ارتفاع كامل
        const Expanded(
          flex: 1,
          child: CheckoutPanel(),
        ),
      ],
    );
  }

  // 📱 التخطيط العمودي (Mobile)
  Widget _buildVerticalLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔍 البحث
          _buildSearchBar(),
          const SizedBox(height: 12),
          // 🛒 السلة
          SizedBox(
            height: 350,
            child: _buildCartSection(),
          ),
          const SizedBox(height: 16),
          // 💳 Checkout
          const CheckoutPanel(),
        ],
      ),
    );
  }

  // 🛒 قسم السلة
  Widget _buildCartSection() {
    final cart = ref.watch(cartProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'السلة',
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.itemCount} منتج',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildCartItem(cart.items[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'السلة فارغة',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ابحث عن منتج أو امسح الباركود',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(SaleItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // حذف
          IconButton(
            onPressed: () => ref.read(cartProvider).removeItem(index),
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.error,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            tooltip: 'حذف',
          ),
          const SizedBox(width: 6),

          // الاسم والوحدة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unit.arabicName,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showChangeUnitDialog(item, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz,
                                size: 10, color: AppColors.info),
                            const SizedBox(width: 2),
                            Text(
                              'تغيير',
                              style: GoogleFonts.tajawal(
                                fontSize: 9,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // الكمية
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(cartProvider)
                          .updateQuantity(index, item.quantity - 1);
                    } catch (e) {
                      if (mounted) {
                        AppToast.error(context,
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    }
                  },
                  icon: const Icon(Icons.remove, size: 14),
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.quantity.toInt()}',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(cartProvider)
                          .updateQuantity(index, item.quantity + 1);
                    } catch (e) {
                      if (mounted) {
                        AppToast.error(context,
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    }
                  },
                  icon: const Icon(Icons.add, size: 14),
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // السعر
          Text(
            _formatPrice(item.total.toInt()),
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // معالجة البحث
  Future<void> _handleSearchSubmit(String query) async {
    if (query.trim().isEmpty) return;

    final productsAsync = ref.read(posControllerProvider);

    productsAsync.when(
      data: (allProducts) {
        _performSearch(query, allProducts);
      },
      loading: () {
        AppToast.info(context, 'جاري تحميل المنتجات...');
      },
      error: (e, _) {
        AppToast.error(context, 'خطأ في تحميل المنتجات');
      },
    );
  }

  void _performSearch(String query, List<Product> allProducts) {
    // إغلاق القائمة المنسدلة
    _hideOverlay();

    // البحث بالباركود أولاً (exact match)
    final exactMatch =
        allProducts.where((p) => p.barcode == query.trim()).toList();

    if (exactMatch.isNotEmpty) {
      final product = exactMatch.first;
      _addToCartDirectly(product, product.baseUnit);
      _searchController.clear();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
      return;
    }

    // إذا كانت هناك نتائج في القائمة المنسدلة، أضف الأول
    // ✨ إذا كانت هناك نتائج، استخدم العنصر المحدد بالأسهم
    if (_searchResults.isNotEmpty) {
      final safeIndex = _selectedIndex.clamp(0, _searchResults.length - 1);
      final product = _searchResults[safeIndex];
      _selectProduct(product);
      _searchResults = [];
      return;
    }

    // البحث بالاسم
    final nameMatches = allProducts
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.scientificName?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            p.barcode.contains(query))
        .toList();

    if (nameMatches.length == 1) {
      final product = nameMatches.first;
      _addToCartDirectly(product, product.baseUnit);
      _searchController.clear();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else if (nameMatches.isEmpty) {
      AppToast.info(context, 'لم يتم العثور على منتج');
    } else {
      // أضف أول نتيجة مباشرة
      final product = nameMatches.first;
      _addToCartDirectly(product, product.baseUnit);
      _searchController.clear();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  Future<void> _addToCartDirectly(Product product, MedicineUnit unit) async {
    try {
      await ref.read(cartProvider).addItemWithUnit(product, unit);
      if (mounted) {
        AppToast.success(context, 'تمت إضافة ${product.name} للسلة ✓');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showChangeUnitDialog(SaleItem item, int index) async {
    // ✨ استخدام Sync-Aware DAO للتوافق مع الكاشير المتعدد
    final syncDao = ref.read(syncAwareProductDaoProvider);
    final product = await syncDao.findById(item.productId);
    if (product == null || !mounted) return;

    final units = product.unitInfo.keys.toList();
    if (units.length == 1) {
      AppToast.info(context, 'هذا المنتج له وحدة واحدة فقط');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تغيير الوحدة',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: units.map((unit) {
            final info = product.unitInfo[unit]!;
            final isSelected = unit == item.unit;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(unit.arabicName, style: GoogleFonts.tajawal()),
              subtitle: Text('${info.sellingPrice.toInt()} د.ع',
                  style: GoogleFonts.tajawal(fontSize: 12)),
              onTap: isSelected
                  ? null
                  : () async {
                      try {
                        ref.read(cartProvider).removeItem(index);
                        await ref
                            .read(cartProvider)
                            .addItemWithUnit(product, unit);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          AppToast.success(context, 'تم تغيير الوحدة ✓');
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          AppToast.error(context,
                              e.toString().replaceAll('Exception: ', ''));
                        }
                      }
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted د.ع';
  }
}
