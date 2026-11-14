import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

@immutable
class ThemeTokens {
  const ThemeTokens({
    required this.key,
    required this.label,
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.primary,
    required this.accentDeep,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.blush,
    required this.error,
    required this.shadowLight,
    required this.shadowWarm,
    required this.gradientEdge,
    required this.blobCaramel,
    required this.blobBlush,
    required this.dark,
    required this.pixel,
    required this.hardShadows,
    required this.radiusScale,
  });

  final String key;
  final String label;
  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color primary;
  final Color accentDeep;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color blush;
  final Color error;
  final Color shadowLight;
  final Color shadowWarm;
  final Color gradientEdge;
  final Color blobCaramel;
  final Color blobBlush;
  final bool dark;
  final bool pixel;
  final bool hardShadows;
  final double radiusScale;

  String get displayFamily => pixel ? 'PixelifySans' : 'Fraunces';
  String get bodyFamily => pixel ? 'PixelifySans' : 'PlusJakartaSans';
}

class ThemePresets {
  ThemePresets._();

  static const vanilla = ThemeTokens(
    key: 'vanilla',
    label: 'Vanilla Cream',
    background: Color(0xFFFBF6EA),
    surface: Color(0xFFFFFDF7),
    surfaceSunken: Color(0xFFF3EBD8),
    primary: Color(0xFFE3B778),
    accentDeep: Color(0xFFC48A4A),
    textPrimary: Color(0xFF3B2F22),
    textSecondary: Color(0xFF8C7B66),
    divider: Color(0xFFEADFC8),
    blush: Color(0xFFF2C9B8),
    error: Color(0xFFB3564D),
    shadowLight: Color(0xFFFFFFFF),
    shadowWarm: Color(0x73D9C7A3),
    gradientEdge: Color(0xFFF6EEDB),
    blobCaramel: Color(0x14E3B778),
    blobBlush: Color(0x14F2C9B8),
    dark: false,
    pixel: false,
    hardShadows: false,
    radiusScale: 1.0,
  );

  static const pixel = ThemeTokens(
    key: 'pixel',
    label: 'Pixel Party',
    background: Color(0xFFF7EFD3),
    surface: Color(0xFFFFFBEF),
    surfaceSunken: Color(0xFFE7D9B8),
    primary: Color(0xFFE2663C),
    accentDeep: Color(0xFFB23E22),
    textPrimary: Color(0xFF33261A),
    textSecondary: Color(0xFF8A7A5E),
    divider: Color(0xFFDFCDA4),
    blush: Color(0xFFF2A48C),
    error: Color(0xFFB23E22),
    shadowLight: Color(0xFFFFFFFF),
    shadowWarm: Color(0xE6B49F72),
    gradientEdge: Color(0xFFEFE3C4),
    blobCaramel: Color(0x14E2663C),
    blobBlush: Color(0x14F2A48C),
    dark: false,
    pixel: true,
    hardShadows: true,
    radiusScale: 0.18,
  );

  static const midnight = ThemeTokens(
    key: 'midnight',
    label: 'Midnight Groove',
    background: Color(0xFF191411),
    surface: Color(0xFF221C15),
    surfaceSunken: Color(0xFF2E261D),
    primary: Color(0xFFE3B778),
    accentDeep: Color(0xFFD89B5C),
    textPrimary: Color(0xFFF3EADA),
    textSecondary: Color(0xFFA08F76),
    divider: Color(0xFF3A3125),
    blush: Color(0xFFF2C9B8),
    error: Color(0xFFE58A7B),
    shadowLight: Color(0xFF3A3125),
    shadowWarm: Color(0x66000000),
    gradientEdge: Color(0xFF241D15),
    blobCaramel: Color(0x1FE3B778),
    blobBlush: Color(0x1FF2C9B8),
    dark: true,
    pixel: false,
    hardShadows: false,
    radiusScale: 1.0,
  );

  static const neon = ThemeTokens(
    key: 'neon',
    label: 'Neon Sunset',
    background: Color(0xFF120E1C),
    surface: Color(0xFF1B1430),
    surfaceSunken: Color(0xFF292045),
    primary: Color(0xFFF72585),
    accentDeep: Color(0xFF9D4DFF),
    textPrimary: Color(0xFFF3EDFF),
    textSecondary: Color(0xFFA79BC8),
    divider: Color(0xFF352A55),
    blush: Color(0xFFFF8FD8),
    error: Color(0xFFFF6B8D),
    shadowLight: Color(0xFF2E2547),
    shadowWarm: Color(0x8C0A0714),
    gradientEdge: Color(0xFF1D1533),
    blobCaramel: Color(0x1FF72585),
    blobBlush: Color(0x1F9D4DFF),
    dark: true,
    pixel: false,
    hardShadows: false,
    radiusScale: 1.0,
  );

  static const bubblegum = ThemeTokens(
    key: 'bubblegum',
    label: 'Bubblegum Pop',
    background: Color(0xFFFFF0F5),
    surface: Color(0xFFFFFAFC),
    surfaceSunken: Color(0xFFFFD9E9),
    primary: Color(0xFFFF7BAC),
    accentDeep: Color(0xFFD6336C),
    textPrimary: Color(0xFF43242F),
    textSecondary: Color(0xFFAD7A8D),
    divider: Color(0xFFFFDCEC),
    blush: Color(0xFFFFB7D5),
    error: Color(0xFFD6336C),
    shadowLight: Color(0xFFFFFFFF),
    shadowWarm: Color(0x96F2B7CE),
    gradientEdge: Color(0xFFFFE4EF),
    blobCaramel: Color(0x14FF7BAC),
    blobBlush: Color(0x14FFB7D5),
    dark: false,
    pixel: false,
    hardShadows: false,
    radiusScale: 1.0,
  );

  static const List<ThemeTokens> all = [
    vanilla,
    pixel,
    midnight,
    neon,
    bubblegum,
  ];

  static ThemeTokens forKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return vanilla;
  }
}

class Palette {
  Palette._();

  static ThemeTokens current = ThemePresets.vanilla;
}

class PaletteController extends ChangeNotifier {
  PaletteController({required this._saveTheme});

  final void Function(String key) _saveTheme;

  ThemeTokens get current => Palette.current;

  void setTheme(String key) {
    final tokens = ThemePresets.forKey(key);
    if (tokens.key == Palette.current.key) return;
    Palette.current = tokens;
    _saveTheme(key);
    applySystemChrome(tokens);
    notifyListeners();
  }
}

void applySystemChrome(ThemeTokens tokens) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: tokens.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: tokens.background,
      systemNavigationBarIconBrightness: tokens.dark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}
