import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_library.dart';
import 'screens/home_page.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_player_app.audio',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );
  runApp(const MusicPlayerBootstrap());
}

class MusicPlayerBootstrap extends StatefulWidget {
  const MusicPlayerBootstrap({super.key});

  @override
  State<MusicPlayerBootstrap> createState() => _MusicPlayerBootstrapState();
}

class _MusicPlayerBootstrapState extends State<MusicPlayerBootstrap> {
  SharedPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      if (!mounted) return;
      setState(() => _preferences = preferences);
    } on Object {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MusicPlayerApp(
      preferences: _preferences,
      backgroundReady: Future<void>.value(),
    );
  }
}

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({
    this.preferences,
    required this.backgroundReady,
    super.key,
  });

  final SharedPreferences? preferences;
  final Future<void> backgroundReady;

  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  late final ThemeProvider _themeProvider = ThemeProvider(
    preferences: widget.preferences,
  );
  late final AudioLibraryController _audioLibrary = AudioLibraryController(
    preferences: widget.preferences,
    backgroundReady: widget.backgroundReady,
  );

  @override
  void dispose() {
    _themeProvider.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_themeProvider, _audioLibrary]),
      builder: (context, child) {
        final accent = _audioLibrary.nowPlayingAccent;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Music Player',
          theme: AppTheme.light(accent),
          darkTheme: AppTheme.dark(accent),
          themeMode: _themeProvider.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 900),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: HomePage(
            themeProvider: _themeProvider,
            audioLibrary: _audioLibrary,
          ),
        );
      },
    );
  }
}
