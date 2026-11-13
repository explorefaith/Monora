import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static const String serif = 'Fraunces';
  static const String sans = 'PlusJakartaSans';
  static const String bangla = 'HindSiliguri';

  static const List<String> _fallback = [bangla];
  static const List<FontVariation> _serifBase = [
    FontVariation('SOFT', 0),
    FontVariation('WONK', 0),
  ];

  static List<FontVariation> _serif(double wght, double opsz) => [
    ..._serifBase,
    FontVariation('wght', wght),
    FontVariation('opsz', opsz),
  ];

  static List<FontVariation> _sansVars(double wght) => [
    FontVariation('wght', wght),
  ];

  static TextStyle get display => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: _fallback,
    fontVariations: _serif(700, 72),
    fontSize: 32,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get title => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: _fallback,
    fontVariations: _serif(600, 36),
    fontSize: 20,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get songTitle => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: _fallback,
    fontVariations: _sansVars(600),
    fontSize: 16,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get artist => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: _fallback,
    fontVariations: _sansVars(400),
    fontSize: 13,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: _fallback,
    fontVariations: _sansVars(500),
    fontSize: 11,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static TextStyle get body => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: _fallback,
    fontVariations: _sansVars(400),
    fontSize: 14,
    height: 1.3,
    color: AppColors.textPrimary,
  );
}
