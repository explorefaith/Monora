# Monora

A warm, creamy Flutter (Android) music player for **local songs** and **online songs** (Deezer previews), built to the spec in [prompt.md](prompt.md).

## Features

- **Library** — local Songs / Albums / Artists from device storage with a friendly permission flow (READ_MEDIA_AUDIO on Android 13+, storage permission below; permanently-denied opens Settings).
- **Discover** — online chips [Bengali, Hindi, English, Trending] via the Deezer public API (charts + curated search seeds, 30s previews marked with a "30s" chip). Pull-to-refresh, shimmer skeleton, error + Retry, offline state.
- **Favorites** — persisted locally (shared_preferences).
- **One queue for everything** — local and online tracks share a single `Track` model and one `AudioPlayer`; previews re-fetch on expiry, broken URLs skip with a snackbar.
- **Player** — mini player (swipe left/right = next/prev, tap/swipe up = expand), full player with palette-tinted background, Hero cover art, drag-to-dismiss, custom seek bar, shuffle / repeat off–all–one, reorderable queue sheet.
- **Background playback** — just_audio_background: notification, lock screen, headset buttons; last-played track + position restored on launch (paused).

## Design — "Warm Vanilla Cream"

Soft neumorphic cream: two-layer shadows, sticky squish press states (0.96 scale, easeOutBack spring-back), Fraunces + Plus Jakarta Sans, Hind Siliguri bundled for Bangla titles, 8pt grid, drifting caramel/blush blobs, reduce-motion respected.

## Build & run

Requires the Flutter SDK (3.50+) and Android SDK (API 36).

```bash
flutter pub get
flutter run                # on a connected device/emulator
flutter build apk --debug  # build/test
flutter analyze            # static analysis (clean)
```

Sign a release build with your own keystore in `android/app/build.gradle.kts` before shipping.

## Structure

```
lib/
  main.dart, app.dart
  core/        theme, colors, text, constants, transitions
  models/      track.dart (one shared model, local + online)
  services/    local_service (on_audio_query), deezer_service, storage_service
  player/      player_controller.dart (single source of truth)
  screens/     splash, home, library_tab, discover_tab, favorites_tab, player_screen
  widgets/     mini_player, track_tile, squish_button, seek_bar, shimmer_list, cover_art
```

Pinned dependency versions live in [pubspec.yaml](pubspec.yaml) (just_audio 0.10.6 — note `ConcatenatingAudioSource` was removed in 0.10, the queue uses `setAudioSources`).

## First push to GitHub

See [github.txt](github.txt).
