import 'package:material_ui/material_ui.dart';

/// 8pt grid only (§2).
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Screen horizontal padding (§2).
const double kPagePadding = 20;

// Component sizes (§2).
const double kListTileHeight = 72;
const double kCoverSmall = 56;
const double kCoverGap = 14;
const double kRadiusCard = 24;
const double kRadiusMini = 28;
const double kRadiusCover = 28;
const double kRadiusCoverLarge = 32;
const double kTapTarget = 44;
const double kPlayButtonSize = 72;

// Motion (§6): micro 120ms, UI 250ms, page 350ms.
const Duration kMicro = Duration(milliseconds: 120);
const Duration kUi = Duration(milliseconds: 250);
const Duration kPage = Duration(milliseconds: 350);
const Curve kEnter = Curves.easeOutCubic;
const Curve kExit = Curves.easeInCubic;
const Curve kSpring = Curves.easeOutBack;
const Duration kBlobsLoop = Duration(seconds: 20);

// Deezer public API (§1).
const String kDeezerHost = 'api.deezer.com';
const int kDiscoverLimit = 30;
const String kTrendingChip = 'Trending';

/// Pre-seeded curated queries per language chip (§3.B). Deezer has no
/// language charts — a raw "Bengali" query returns junk — so each chip
/// rotates through curated seeds on pull-to-refresh.
const Map<String, List<String>> kDiscoverSeeds = {
  'Bengali': ['Bengali modern songs', 'Anupam Roy', 'Bengali hits'],
  'Hindi': ['Hindi top hits', 'Arijit Singh', 'Shreya Ghoshal'],
  'English': ['English pop hits', 'Ed Sheeran', 'Taylor Swift'],
};

/// Staggered list reveal (§6): offset 16px, 40ms stagger, max 8 items.
const int kStaggerMaxItems = 8;
const Duration kStaggerStep = Duration(milliseconds: 40);
