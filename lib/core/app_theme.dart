import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Light "Warm Vanilla Cream" theme — the only theme in v1 (§2).
class AppTheme {
  AppTheme._();

  static ThemeData light() {
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
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentDeep,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory, // ripples replaced by squish (§6)
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accentDeep,
        selectionColor: AppColors.primary,
        selectionHandleColor: AppColors.accentDeep,
      ),
    );
  }
}
