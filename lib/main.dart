import 'package:flutter/material.dart';

import 'audio/audio_library.dart';
import 'screens/home_page.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({super.key});

  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final AudioLibraryController _audioLibrary = AudioLibraryController();

  @override
  void dispose() {
    _themeProvider.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Music Player',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeProvider.themeMode,
          home: HomePage(
            themeProvider: _themeProvider,
            audioLibrary: _audioLibrary,
          ),
        );
      },
    );
  }
}
