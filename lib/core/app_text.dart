import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'palette.dart';

/// Typography driven by the active theme: Fraunces (serif) for the cream
/// themes, Pixelify Sans for Pixel Party; body in Plus Jakarta Sans.
/// Hind Siliguri stays bundled as the Bangla glyph fallback everywhere.
class AppText {
  AppText._();

  static const String serif = 'Fraunces';
  static const String sans = 'PlusJakartaSans';
  static const String bangla = 'HindSiliguri';

  static const List<String> _fallback = [bangla];

  static List<FontVariation> _displayVars(
    ThemeTokens t,
    double wght,
    double opsz,
  ) {
    if (t.pixel) return [FontVariation('wght', wght)];
    return [
      const FontVariation('SOFT', 0),
      const FontVariation('WONK', 0),
      FontVariation('wght', wght),
      FontVariation('opsz', opsz),
    ];
  }

  static List<FontVariation> _bodyVars(ThemeTokens t, double wght) => [
    FontVariation('wght', wght),
  ];

  // Scale: display 32/700, title 20/600, song title 16/600, artist 13/400,
  // caption 11/500. Line height 1.3; serif gets -0.2 tracking.
  static TextStyle get display {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.displayFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _displayVars(t, 700, 72),
      fontSize: 32,
      height: 1.3,
      letterSpacing: t.pixel ? 0 : -0.2,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get title {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.displayFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _displayVars(t, 600, 36),
      fontSize: 20,
      height: 1.3,
      letterSpacing: t.pixel ? 0 : -0.2,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get songTitle {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.bodyFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _bodyVars(t, 600),
      fontSize: 16,
      height: 1.3,
      letterSpacing: t.pixel ? 0 : -0.1,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get artist {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.bodyFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _bodyVars(t, 400),
      fontSize: 13,
      height: 1.3,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get caption {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.bodyFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _bodyVars(t, 500),
      fontSize: 11,
      height: 1.3,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get body {
    final t = Palette.current;
    return TextStyle(
      fontFamily: t.bodyFamily,
      fontFamilyFallback: _fallback,
      fontVariations: _bodyVars(t, 400),
      fontSize: 14,
      height: 1.3,
      color: AppColors.textPrimary,
    );
  }
}
