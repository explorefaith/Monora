import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../player/player_controller.dart';
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
