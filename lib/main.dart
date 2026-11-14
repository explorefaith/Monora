import 'package:material_ui/material_ui.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/palette.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'dev.explorefaith.monora.playback',
    androidNotificationChannelName: 'Monora playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: false,
  );
  final storage = StorageService();
  await storage.init();
  Palette.current = ThemePresets.forKey(storage.themeKey);
  applySystemChrome(Palette.current);
  runApp(MonoraApp(storage: storage));
}
