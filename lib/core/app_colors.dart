import 'package:material_ui/material_ui.dart';

import 'palette.dart';

/// Live palette accessors — every value routes through the active theme
/// ([Palette.current]), so widgets read the themed color with zero
/// call-site changes.
class AppColors {
  AppColors._();

  static Color get background => Palette.current.background;
  static Color get surface => Palette.current.surface;
  static Color get surfaceSunken => Palette.current.surfaceSunken;
  static Color get primary => Palette.current.primary;
  static Color get accentDeep => Palette.current.accentDeep;
  static Color get textPrimary => Palette.current.textPrimary;
  static Color get textSecondary => Palette.current.textSecondary;
  static Color get divider => Palette.current.divider;
  static Color get blush => Palette.current.blush;
  static Color get error => Palette.current.error;

  static Color get shadowLight => Palette.current.shadowLight;
  static Color get shadowWarm => Palette.current.shadowWarm;

  static Color get gradientEdge => Palette.current.gradientEdge;
  static Color get blobCaramel => Palette.current.blobCaramel;
  static Color get blobBlush => Palette.current.blobBlush;
}
