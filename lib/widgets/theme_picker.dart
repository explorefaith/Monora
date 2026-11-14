import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../core/palette.dart';
import 'squish_button.dart';

Future<void> showThemeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ThemeSheet(),
  );
}

class ThemeSheet extends StatelessWidget {
  const ThemeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kPagePadding,
          0,
          kPagePadding,
          Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Text('Themes', style: AppText.title),
            ),
            const SizedBox(height: Spacing.lg),
            Consumer<PaletteController>(
              builder: (context, palette, _) {
                return Column(
                  children: [
                    for (final tokens in ThemePresets.all)
                      _ThemeRow(
                        tokens: tokens,
                        selected: palette.current.key == tokens.key,
                        onTap: () => palette.setTheme(tokens.key),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.tokens,
    required this.selected,
    required this.onTap,
  });

  final ThemeTokens tokens;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Radii.field);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kMicro,
        curve: kEnter,
        margin: const EdgeInsets.only(bottom: Spacing.md),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSunken : AppColors.surface,
          borderRadius: radius,
          boxShadow: selected ? kCreamShadowsPressed : creamShadows(),
          border: Border.all(
            color: selected ? AppColors.accentDeep : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: BorderRadius.circular(12 * tokens.radiusScale),
                border: Border.all(color: tokens.divider),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: tokens.displayFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tokens.label,
                    style: AppText.songTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _swatch(tokens.background),
                      _swatch(tokens.surface),
                      _swatch(tokens.primary),
                      _swatch(tokens.accentDeep),
                      _swatch(tokens.textPrimary),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: AppColors.accentDeep),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
    width: 18,
    height: 12,
    margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(tokens.pixel ? 1 : 3),
      border: Border.all(color: AppColors.divider),
    ),
  );
}
