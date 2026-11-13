import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../models/track.dart';
import '../player/player_controller.dart';
import '../services/deezer_service.dart';
import '../widgets/shimmer_list.dart';
import '../widgets/squish_button.dart';
import '../widgets/track_tile.dart';

enum _Status { loading, ready, error, offline, empty }

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  static const _chips = ['Bengali', 'Hindi', 'English', kTrendingChip];

  String _selected = 'Bengali';
  int _seedIndex = 0;
  _Status _status = _Status.loading;
  List<Track> _tracks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool bumpSeed = false}) async {
    setState(() => _status = _Status.loading);
    if (bumpSeed) _seedIndex++;
    final service = context.read<DeezerService>();
    try {
      List<Track> result;
      if (_selected == kTrendingChip) {
        result = await service.trending();
      } else {
        final seeds = kDiscoverSeeds[_selected] ?? const <String>[];
        final query = seeds.isEmpty
            ? _selected
            : seeds[_seedIndex % seeds.length];
        result = await service.search(query);
      }
      if (!mounted) return;
      setState(() {
        _tracks = result;
        _status = result.isEmpty ? _Status.empty : _Status.ready;
      });
    } on OfflineException {
      if (!mounted) return;
      setState(() => _status = _Status.offline);
    } catch (e) {
      debugPrint('discover load failed: $e');
      if (!mounted) return;
      setState(() => _status = _Status.error);
    }
  }

  void _play(int index) {
    context.read<PlayerController>().playQueue(_tracks, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              Spacing.lg,
              kPagePadding,
              Spacing.sm,
            ),
            child: Text('Discover', style: AppText.display),
          ),
          _chipsRow(),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentDeep,
              onRefresh: () => _load(bumpSeed: true),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, i) {
          final chip = _chips[i];
          final selected = chip == _selected;
          return PressableScale(
            onTap: () {
              if (selected) return;
              setState(() {
                _selected = chip;
                _seedIndex = 0;
              });
              _load();
            },
            child: AnimatedContainer(
              duration: kMicro,
              curve: kEnter,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.surfaceSunken : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected ? kCreamShadowsPressed : kCreamShadows,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accentDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    chip,
                    style: selected
                        ? AppText.caption.copyWith(
                            color: AppColors.accentDeep,
                            fontSize: 13,
                          )
                        : AppText.caption.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    switch (_status) {
      case _Status.loading:
        return ListView(children: const [ShimmerList(itemCount: 8)]);
      case _Status.ready:
        return ListView.builder(
          padding: const EdgeInsets.only(top: Spacing.xs, bottom: Spacing.lg),
          scrollCacheExtent: const ScrollCacheExtent.pixels(500),
          itemCount: _tracks.length,
          itemBuilder: (context, i) =>
              TrackTile(track: _tracks[i], index: i, onTap: () => _play(i)),
        );
      case _Status.empty:
        return _stateCard(
          icon: Icons.music_off_outlined,
          title: 'Nothing here yet',
          message:
              'No results for this one. Pull to refresh or try another chip.',
        );
      case _Status.offline:
        return _stateCard(
          icon: Icons.wifi_off_outlined,
          title: "You're offline",
          message: 'Connect to the internet to browse online songs. Your local library still works.',
        );
      case _Status.error:
        return _stateCard(
          icon: Icons.cloud_off_outlined,
          title: 'Something went wrong',
          message: 'Could not load this list right now.',
          actionLabel: 'Retry',
          action: () => _load(),
        );
    }
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? action,
  }) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(kRadiusCard),
              boxShadow: kCreamShadows,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: Spacing.lg),
                  Text(title, style: AppText.title),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppText.artist.copyWith(fontSize: 14, height: 1.5),
                  ),
                  if (actionLabel != null && action != null) ...[
                    const SizedBox(height: Spacing.xl),
                    SquishFilledButton(label: actionLabel, onTap: action),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
