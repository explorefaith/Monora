import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../player/player_controller.dart';
import '../widgets/squish_button.dart';
import '../widgets/theme_picker.dart';
import '../widgets/track_tile.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    final favorites = controller.favorites;

    return SafeArea(
      child: favorites.isEmpty
          ? _emptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kPagePadding,
                    Spacing.lg,
                    kPagePadding,
                    Spacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Favorites', style: AppText.display),
                      ),
                      SquishIconButton(
                        icon: Icons.palette_outlined,
                        onTap: () => showThemeSheet(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: Spacing.lg),
                    scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) => TrackTile(
                      track: favorites[i],
                      index: i,
                      onTap: () => context.read<PlayerController>().playQueue(
                        favorites,
                        initialIndex: i,
                      ),
                      trailing: SquishIconButton(
                        icon: Icons.favorite,
                        iconColor: AppColors.accentDeep,
                        selected: true,
                        onTap: () => context
                            .read<PlayerController>()
                            .toggleFavorite(favorites[i]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(kPagePadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: creamShadows(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 40, color: AppColors.blush),
              const SizedBox(height: Spacing.lg),
              Text('Songs you love live here', style: AppText.title),
              const SizedBox(height: Spacing.sm),
              Text(
                'Tap the heart on any song and it will keep you company.',
                textAlign: TextAlign.center,
                style: AppText.artist.copyWith(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
