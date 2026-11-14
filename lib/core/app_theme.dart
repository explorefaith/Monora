import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'constants.dart';
import 'palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build(ThemeTokens t) {
    final textTheme = TextTheme(
      displayLarge: AppText.display,
      headlineSmall: AppText.title,
      titleMedium: AppText.songTitle,
      bodyMedium: AppText.body,
      bodySmall: AppText.artist,
      labelSmall: AppText.caption,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: t.dark ? Brightness.dark : Brightness.light,
        primary: AppColors.accentDeep,
        onPrimary: AppColors.surface,
        secondary: AppColors.primary,
        onSecondary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceSunken,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accentDeep,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppText.songTitle.copyWith(fontSize: 14),
        unselectedLabelStyle: AppText.artist.copyWith(fontSize: 14),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: AppColors.accentDeep,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppText.artist.copyWith(
          color: AppColors.surface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.mini)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentDeep,
        selectionColor: AppColors.primary,
        selectionHandleColor: AppColors.accentDeep,
      ),
    );
  }
}
