import 'package:material_ui/material_ui.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'services/storage_service.dart';

/// just_audio_background MUST be initialised before runApp (§4) so the
/// media notification / lock-screen controls / headset buttons work.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'dev.explorefaith.monora.playback',
    androidNotificationChannelName: 'Monora playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  final storage = StorageService();
  await storage.init();
  runApp(MonoraApp(storage: storage));
}
