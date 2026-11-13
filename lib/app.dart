import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'player/player_controller.dart';
import 'screens/splash.dart';
import 'services/deezer_service.dart';
import 'services/local_service.dart';
import 'services/storage_service.dart';

class MonoraApp extends StatelessWidget {
  const MonoraApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalService>(create: (_) => LocalService()),
        Provider<DeezerService>(create: (_) => DeezerService()),
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<PlayerController>(
          create: (context) => PlayerController(
            storage: context.read<StorageService>(),
            deezer: context.read<DeezerService>(),
          )..initAudioSession(),
        ),
      ],
      child: MaterialApp(
        title: 'Monora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
