import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Cached text styles for auth module
/// Uses LOCAL fonts from assets/fonts/ - NO INTERNET REQUIRED
///
/// ✅ Using embedded fonts instead of GoogleFonts for:
/// - Offline functionality
/// - Faster startup
/// - Consistent experience
class AuthStyles {
  AuthStyles._();

  // ✅ Base font family - matches pubspec.yaml
  static const String _fontFamily = 'Tajawal';

  // Headings
  static const heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body text
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  // Labels
  static const label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Error text
  static const error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    color: AppColors.error,
  );

  // Primary colored text
  static const primaryText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Link style
  static const link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.primary,
  );

  // Button text
  static const button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Footer text
  static const footer = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static const footerSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    color: AppColors.textSecondary,
  );
}
