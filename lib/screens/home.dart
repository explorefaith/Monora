import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/constants.dart';
import '../player/player_controller.dart';
import '../services/battery_service.dart';
import '../services/storage_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/texture_overlay.dart';
import '../widgets/squish_button.dart';
import 'discover_tab.dart';
import 'favorites_tab.dart';
import 'library_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  StreamSubscription<String>? _messagesSub;
  bool _showBatteryHint = false;

  static const _tabs = [
    (icon: Icons.library_music_outlined, label: 'Library'),
    (icon: Icons.explore_outlined, label: 'Discover'),
    (icon: Icons.favorite_outline, label: 'Favorites'),
  ];

  @override
  void initState() {
    super.initState();

    _messagesSub = context.read<PlayerController>().messages.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    final dismissed = context.read<StorageService>().batteryHintDismissed;
    if (dismissed) return;
    final ignoring = await context.read<BatteryService>().isIgnoring();
    if (!mounted || ignoring) return;
    setState(() => _showBatteryHint = true);
  }

  Future<void> _allowBattery() async {
    final battery = context.read<BatteryService>();
    final storage = context.read<StorageService>();
    final dialogShown = await battery.requestIgnore();
    await storage.dismissBatteryHint();
    if (mounted) {
      setState(() => _showBatteryHint = false);
      if (!dialogShown) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Opened app settings — set Battery to Unrestricted for Monora.',
              ),
            ),
          );
      }
    }
  }

  Future<void> _dismissBattery() async {
    await context.read<StorageService>().dismissBatteryHint();
    if (mounted) setState(() => _showBatteryHint = false);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: const [LibraryTab(), DiscoverTab(), FavoritesTab()],
          ),
          const Positioned.fill(child: TextureOverlay()),
          if (_showBatteryHint)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: kPagePadding,
              right: kPagePadding,
              child: _BatteryHintCard(
                onAllow: _allowBattery,
                onDismiss: _dismissBattery,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _PillNavBar(
            tabs: _tabs,
            current: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
        ],
      ),
    );
  }
}

class _BatteryHintCard extends StatelessWidget {
  const _BatteryHintCard({required this.onAllow, required this.onDismiss});

  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        boxShadow: kCreamShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.battery_saver,
              size: 26,
              color: AppColors.accentDeep,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep the music running',
                    style: AppText.songTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Android may stop Monora in the background to save battery. Allow it to run without restrictions.',
                    style: AppText.artist.copyWith(fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      SquishButton(
                        onTap: onAllow,
                        height: 38,
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                          ),
                          child: Text(
                            'Allow',
                            style: AppText.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      PressableScale(
                        onTap: onDismiss,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.sm,
                          ),
                          child: Text(
                            'Later',
                            style: AppText.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.tabs,
    required this.current,
    required this.onSelected,
  });

  final List<({IconData icon, String label})> tabs;
  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.md),
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: kCreamShadows,
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: PressableScale(
                onTap: () => onSelected(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].icon,
                      size: 22,
                      color: i == current
                          ? AppColors.accentDeep
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: Spacing.xs + 2),
                    AnimatedContainer(
                      duration: kMicro,
                      curve: kEnter,
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == current
                            ? AppColors.accentDeep
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
