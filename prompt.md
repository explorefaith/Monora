Build a complete Flutter (Android) music player app called "Monora".

════════════ 1. PRODUCT ════════════
- Plays LOCAL songs from device storage (cover art, title, artist) and ONLINE songs
  (latest Bengali, Hindi, English, and a "Trending" tab).
- Online data: Deezer public API (charts, search, 30s preview) behind a service class
  so Audius/Jamendo (full-length) can be added later as another provider.
- One shared `Track` model (id, title, artist, uri, artUrl, localId, isLocal, isPreview)
  so the UI and player never care where a song came from.
- Packages (already in pubspec, PIN exact versions — just_audio 0.10+ removed
  ConcatenatingAudioSource): just_audio, just_audio_background, on_audio_query,
  audio_session, http, cached_network_image, rxdart.
- Persistence: shared_preferences for favorites + last-played (no hive).
  Add provider or riverpod only if needed.

════════════ 2. DESIGN LANGUAGE: "Warm Vanilla Cream" ════════════
Feel: soft, tactile, slightly sticky like cream or icing. Calm, premium, no harsh edges.

Colors (define in a single AppColors class, no hardcoded colors elsewhere):
- background        #FBF6EA  (vanilla white)
- surface           #FFFDF7  (cream white, cards)
- surfaceSunken     #F3EBD8  (pressed / inset areas)
- primary accent    #E3B778  (honey caramel)
- accentDeep        #C48A4A  (toasted caramel, active icons, progress)
- textPrimary       #3B2F22  (warm espresso, never pure black)
- textSecondary     #8C7B66
- divider           #EADFC8
- Optional soft blush highlight #F2C9B8 for the favorite heart.
- Light theme only for v1.

"Sticky / creamy" tactile feel (important):
- Large radii: cards 24, mini player 28, buttons fully round, cover art 28.
- Two-layer soft shadows instead of borders: one light (white, offset -4,-4, blur 10)
  and one warm (#D9C7A3 at 45% opacity, offset 6,6, blur 16) = neumorphic cream look.
- Pressed state: shadows invert to inset look, scale to 0.96, 120ms easeOut,
  then spring back with easeOutBack ("sticky squish").
- Subtle cream texture: a very faint noise or paper-grain overlay (3 to 4% opacity)
  on the background, plus a soft radial gradient (#FFFDF7 center to #F6EEDB edge).
- Tinted blobs: 2 large blurred circles of caramel/blush (8% opacity) drifting slowly
  behind the player screen, 20s loop.

Typography (google_fonts or bundled assets):
- Headings and song titles: "Fraunces" or "DM Serif Display" (soft, creamy serif)
- Body, artist, labels: "Plus Jakarta Sans" or "Nunito"
- Scale: display 32/700, title 20/600, song title 16/600, artist 13/400, caption 11/500
- Line height 1.3, letter spacing -0.2 for headings. Ellipsis on long titles, maxLines 1.
- Bangla titles must render properly: BUNDLE "Hind Siliguri" as an asset font
  (not runtime google_fonts) and set it via fontFamilyFallback in the theme.

Spacing and alignment:
- 8pt grid only (4, 8, 12, 16, 24, 32). Screen horizontal padding 20.
- List tile: 72 height, 56x56 cover (radius 16), 14 gap, title/artist column vertically
  centered, trailing icon 44x44 tap target.
- Everything left-aligned except the player screen (center-aligned).
- Respect SafeArea, keyboard insets, and notches. Support all screen sizes (no overflow).

════════════ 3. SCREENS ════════════
A) Splash: "Monora" wordmark fades and scales in (600ms), tiny wave animation, then
   crossfade to Home.

B) Home with bottom nav (floating pill style nav bar, cream surface, caramel active dot):
   1. Library (Local): tabs Songs / Albums / Artists. Search bar on top.
      Permission flow: friendly cream-colored explainer card, then request
      READ_MEDIA_AUDIO (Android 13+) or READ_EXTERNAL_STORAGE. Handle denied and
      permanently denied (button opens app settings).
   2. Discover (Online): chips row [Bengali, Hindi, English, Trending]. Each chip loads
      its list via pre-seeded curated search queries / artist lists defined in constants
      (Deezer has NO language charts — do not rely on a raw "Bengali" query).
      Pull-to-refresh, shimmer skeleton while
      loading, error state with Retry, offline state.
   3. Favorites: stored locally (shared_preferences or hive).

C) Mini player (docked above nav bar, persists across tabs):
   - Cover, title, artist, play/pause, next. Thin progress line at the bottom.
   - Swipe left/right = next/previous, swipe up or tap = expand to full player
     with a Hero transition on the cover art.

D) Full player screen:
   - Big cover (square, radius 32, double shadow), gently scales to 0.92 when paused and
     1.0 when playing (400ms easeOutCubic).
   - Background tint extracted from the cover (palette_generator) blended 15% into cream.
   - Title (serif), artist, favorite heart (pop animation), seek bar (custom thick
     rounded track, caramel thumb with glow), elapsed / remaining time,
     controls: shuffle, previous, BIG play/pause (72px cream button with deep shadow),
     next, repeat (off / all / one). Volume not needed.
   - Queue bottom sheet (draggable) showing upcoming tracks, reorder by drag.

════════════ 4. PLAYER LOGIC ════════════
- Single PlayerController (ChangeNotifier or Riverpod notifier) owning one AudioPlayer
  + a playlist set via player.setAudioSources(List<AudioSource>) (the just_audio 0.10+
  API — ConcatenatingAudioSource no longer exists); expose streams combined with rxdart:
  position, bufferedPosition, duration, playerState, currentIndex.
- Play/Pause button MUST work from: full player, mini player, notification, lock screen,
  headset buttons. Single source of truth = playerState.playing stream, never local bool.
- Button states: loading (circular caramel spinner), buffering, playing (pause icon),
  paused (play icon), completed. Animate icon with AnimatedIcon (play_pause) 250ms.
- Debounce rapid taps; seek only on drag end (onChangeEnd), preview position while dragging.
- Next/previous: previous restarts the song if position > 3s, else goes to prior track.
- Configure audio_session for focus + "becoming noisy" events (just_audio_background
  does not cover all of it).
- Handle: audio focus loss/gain, headphones unplugged (auto pause), phone calls,
  broken URLs (skip to next with snackbar), expired Deezer preview URLs
  (re-fetch before play), end of queue.
- Background playback: just_audio_background initialised in main() before runApp
  (androidNotificationChannelId, ongoing notification, MediaItem with title, artist, artUri).
- Local cover art: on_audio_query returns BYTES, not URIs — cache artwork to a file
  in the app support dir once per song id and pass that file URI to MediaItem.artUri,
  or the notification/lock screen shows no art.
- Online and local tracks go through same queue. Mark previews with a small "30s" chip.
- Remember last played track and position, restore on launch (paused).

════════════ 5. ANDROID CONFIG ════════════
- AndroidManifest: INTERNET, POST_NOTIFICATIONS (required for the media notification
  on Android 13+), READ_MEDIA_AUDIO, READ_EXTERNAL_STORAGE (maxSdk 32),
  FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK, WAKE_LOCK;
  declare the just_audio_background service and MediaButtonReceiver;
  usesCleartextTraffic stays DISABLED (Deezer preview CDN is HTTPS).
- MainActivity extends AudioServiceActivity. minSdk 23, compile/target latest stable.
- App icon and name "Monora", cream-colored adaptive icon with a simple note/wave mark.

════════════ 6. MOTION RULES (smoothness) ════════════
- 60fps target: use const widgets, RepaintBoundary around the cover art and seek bar,
  ListView.builder with cacheExtent, cached_network_image with memCacheWidth.
- Standard durations: micro 120ms, UI 250ms, page 350ms. Curves: easeOutCubic for
  entering, easeInCubic exiting, easeOutBack for press release.
- List items: staggered fade+slide-up (offset 16px, 40ms stagger, max 8 items).
- Page transitions: fade-through or shared-axis, never default Android slide.
- Mini to full player: Hero cover + sheet expand (DraggableScrollableSheet or custom
  route with drag-to-dismiss).
- Ripples replaced by squish-scale on press (see sticky feel above).
- Respect "reduce motion" (MediaQuery.disableAnimations).
- Never rebuild the whole screen on position ticks: use StreamBuilder/ValueListenableBuilder
  only around the seek bar and time text.

════════════ 7. STRUCTURE AND QUALITY ════════════
lib/
  main.dart, app.dart
  core/ (theme/app_colors.dart, app_theme.dart, app_text.dart, constants.dart)
  models/track.dart
  services/ (local_service.dart, deezer_service.dart, storage_service.dart)
  player/player_controller.dart
  screens/ (splash, home, library_tab, discover_tab, favorites_tab, player_screen)
  widgets/ (mini_player, track_tile, squish_button, seek_bar, shimmer_list, cover_art)
- Null-safe, flutter_lints clean, no hardcoded colors or sizes outside core/.
- Each file small and commented only where logic is non-obvious.
- Output: all files in full, then the exact Android manifest/gradle edits, then
  "flutter pub get" and run steps.
- Do NOT use any unofficial scraping APIs (YouTube/JioSaavn). Official public APIs only.
