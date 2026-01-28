import 'package:flutter/material.dart';

/// امتداد للحصول على spacing متجاوب حسب حجم الشاشة
extension ResponsiveSpacing on BuildContext {
  /// حجم الشاشة
  Size get screenSize => MediaQuery.of(this).size;

  /// عرض الشاشة
  double get screenWidth => screenSize.width;

  /// ارتفاع الشاشة
  double get screenHeight => screenSize.height;

  /// هل الجهاز تابلت؟
  bool get isTablet => screenWidth > 600;

  /// هل الجهاز ديسكتوب؟
  bool get isDesktop => screenWidth > 900;

  /// هل الجهاز موبايل؟
  bool get isMobile => screenWidth <= 600;

  // ======================================================================
  // Spacing Values
  // ======================================================================

  double get spacing4 => isTablet ? 6 : 4;
  double get spacing6 => isTablet ? 8 : 6;
  double get spacing8 => isTablet ? 12 : 8;
  double get spacing10 => isTablet ? 14 : 10;
  double get spacing12 => isTablet ? 16 : 12;
  double get spacing16 => isTablet ? 24 : 16;
  double get spacing20 => isTablet ? 28 : 20;
  double get spacing24 => isTablet ? 32 : 24;
  double get spacing28 => isTablet ? 36 : 28;
  double get spacing32 => isTablet ? 40 : 32;

  // ======================================================================
  // Font Sizes
  // ======================================================================

  double get fontSize10 => isTablet ? 12 : 10;
  double get fontSize11 => isTablet ? 13 : 11;
  double get fontSize12 => isTablet ? 14 : 12;
  double get fontSize13 => isTablet ? 15 : 13;
  double get fontSize14 => isTablet ? 16 : 14;
  double get fontSize15 => isTablet ? 17 : 15;
  double get fontSize16 => isTablet ? 18 : 16;
  double get fontSize18 => isTablet ? 20 : 18;
  double get fontSize20 => isTablet ? 22 : 20;
  double get fontSize24 => isTablet ? 28 : 24;
  double get fontSize28 => isTablet ? 32 : 28;

  // ======================================================================
  // Icon Sizes
  // ======================================================================

  double get iconSize16 => isTablet ? 20 : 16;
  double get iconSize18 => isTablet ? 22 : 18;
  double get iconSize20 => isTablet ? 24 : 20;
  double get iconSize22 => isTablet ? 26 : 22;
  double get iconSize24 => isTablet ? 28 : 24;
  double get iconSize28 => isTablet ? 32 : 28;

  // ======================================================================
  // Border Radius
  // ======================================================================

  double get radius6 => isTablet ? 8 : 6;
  double get radius8 => isTablet ? 10 : 8;
  double get radius10 => isTablet ? 12 : 10;
  double get radius12 => isTablet ? 14 : 12;
}
