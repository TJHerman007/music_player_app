import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';
import '../widgets/player_bar.dart';
import '../widgets/music_visual.dart';
import 'collection_page.dart';
import 'library_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.themeProvider,
    required this.audioLibrary,
    super.key,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    widget.audioLibrary.scanDeviceMusic();
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _greetingTimer = Timer(nextMinute.difference(now), () {
      if (mounted) setState(() {});
      if (mounted) _scheduleGreetingRefresh();
    });
  }

  void _scheduleGreetingRefresh() {
    _greetingTimer?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _greetingTimer = Timer(nextMinute.difference(now), () {
      if (mounted) setState(() {});
      if (mounted) _scheduleGreetingRefresh();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('My Music')),
      drawer: _AppDrawer(
        themeProvider: widget.themeProvider,
        audioLibrary: widget.audioLibrary,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.audioLibrary,
        builder: (context, child) => PlayerBar(
          controller: widget.audioLibrary,
          onOpenSource: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LibraryPage(
                themeProvider: widget.themeProvider,
                audioLibrary: widget.audioLibrary,
              ),
            ),
          ),
        ),
      ),
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            await widget.audioLibrary.scanDeviceMusic();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick up where you left off.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              ListenableBuilder(
                listenable: widget.audioLibrary,
                builder: (context, child) => ThreeDAlbumArt(
                  title: 'home',
                  imageBytes: widget.audioLibrary.homeImageBytes,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'All songs',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: widget.audioLibrary,
                builder: (context, child) {
                  if (widget.audioLibrary.tracks.isEmpty) {
                    return const Text(
                      'No songs found. Scan your phone to load your music.',
                    );
                  }
                  return Column(
                    children: widget.audioLibrary.tracks
                        .map(
                          (track) => _HomeTrackTile(
                            track: track,
                            controller: widget.audioLibrary,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.themeProvider, required this.audioLibrary});

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: LiquidGlassSurface(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Text(
                  'Music Player',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded),
                title: const Text('Back'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.home_outlined),
                title: Text('Home'),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.library_music_outlined),
                title: const Text('Library'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LibraryPage(
                        themeProvider: themeProvider,
                        audioLibrary: audioLibrary,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline_rounded),
                title: const Text('Liked songs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CollectionPage(
                        title: 'Liked songs',
                        icon: Icons.favorite_rounded,
                        audioLibrary: audioLibrary,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_outlined),
                title: const Text('Playlists'),
                onTap: () => _openCollection(
                  context,
                  'Playlists',
                  Icons.queue_music_rounded,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Downloads'),
                onTap: () => _openCollection(
                  context,
                  'Downloads',
                  Icons.download_rounded,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        themeProvider: themeProvider,
                        audioLibrary: audioLibrary,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: const Text('Dark mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: themeProvider.toggleTheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCollection(BuildContext context, String title, IconData icon) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionPage(title: title, icon: icon),
      ),
    );
  }
}

class _HomeTrackTile extends StatelessWidget {
  const _HomeTrackTile({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: const Icon(Icons.music_note_rounded),
        title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: controller.isFavorite(track)
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              icon: Icon(
                controller.isFavorite(track)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: controller.isFavorite(track) ? Colors.pinkAccent : null,
              ),
              onPressed: () => controller.toggleFavorite(track),
            ),
            IconButton(
              tooltip: 'Play',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () =>
                  controller.playTrack(track, source: TrackSource.library),
            ),
          ],
        ),
      ),
    );
  }
}
