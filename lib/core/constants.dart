import 'package:material_ui/material_ui.dart';

class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

const double kPagePadding = 20;

const double kListTileHeight = 72;
const double kCoverSmall = 56;
const double kCoverGap = 14;
const double kRadiusCard = 24;
const double kRadiusMini = 28;
const double kRadiusCover = 28;
const double kRadiusCoverLarge = 32;
const double kTapTarget = 44;
const double kPlayButtonSize = 72;

const Duration kMicro = Duration(milliseconds: 120);
const Duration kUi = Duration(milliseconds: 250);
const Duration kPage = Duration(milliseconds: 350);
const Curve kEnter = Curves.easeOutCubic;
const Curve kExit = Curves.easeInCubic;
const Curve kSpring = Curves.easeOutBack;
const Duration kBlobsLoop = Duration(seconds: 20);

const String kDeezerHost = 'api.deezer.com';
const int kDiscoverLimit = 30;
const String kTrendingChip = 'Trending';

const Map<String, List<String>> kDiscoverSeeds = {
  'Bengali': ['Bengali modern songs', 'Anupam Roy', 'Bengali hits'],
  'Hindi': ['Hindi top hits', 'Arijit Singh', 'Shreya Ghoshal'],
  'English': ['English pop hits', 'Ed Sheeran', 'Taylor Swift'],
};

const int kStaggerMaxItems = 8;
const Duration kStaggerStep = Duration(milliseconds: 40);
