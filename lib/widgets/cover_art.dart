import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../models/track.dart';

class CoverArt extends StatelessWidget {
  const CoverArt({super.key, this.track, this.size = 56, this.radius = 16});

  final Track? track;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final t = track;

    Widget? inner;
    if (t != null) {
      if (t.isLocal && t.artUri != null) {
        inner = Image.file(
          File(t.artUri!.toFilePath()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } else if (t.artUrl != null && t.artUrl!.isNotEmpty) {
        inner = CachedNetworkImage(
          imageUrl: t.artUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * dpr).round(),
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, _) => _shimmerFallback(),
          errorWidget: (_, _, _) => _fallback(),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? Radii.tileCover),
      child: inner ?? _fallback(),
    );
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    color: AppColors.surfaceSunken,
    alignment: Alignment.center,
    child: Icon(
      Icons.music_note,
      color: AppColors.accentDeep,
      size: size * 0.4,
    ),
  );

  Widget _shimmerFallback() =>
      Container(width: size, height: size, color: AppColors.surfaceSunken);
}
