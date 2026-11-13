import 'package:material_ui/material_ui.dart';

/// Every color in Monora lives here — no hardcoded colors elsewhere (§2).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFBF6EA); // vanilla white
  static const Color surface = Color(0xFFFFFDF7); // cream white, cards
  static const Color surfaceSunken = Color(0xFFF3EBD8); // pressed / inset
  static const Color primary = Color(0xFFE3B778); // honey caramel
  static const Color accentDeep = Color(0xFFC48A4A); // toasted caramel
  static const Color textPrimary = Color(0xFF3B2F22); // warm espresso
  static const Color textSecondary = Color(0xFF8C7B66);
  static const Color divider = Color(0xFFEADFC8);
  static const Color blush = Color(0xFFF2C9B8); // favorite heart
  static const Color error = Color(0xFFB3564D); // warm brick, never harsh red

  // Two-layer soft shadow pair = neumorphic cream look (§2).
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowWarm = Color(0x73D9C7A3); // #D9C7A3 at 45%

  // Background texture + drifting blobs (§2).
  static const Color gradientEdge = Color(0xFFF6EEDB);
  static const Color blobCaramel = Color(0x14E3B778); // 8%
  static const Color blobBlush = Color(0x14F2C9B8); // 8%
}
