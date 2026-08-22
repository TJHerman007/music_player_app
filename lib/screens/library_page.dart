import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';
import '../widgets/player_bar.dart';
import 'collection_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({
    required this.themeProvider,
    required this.audioLibrary,
    super.key,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      bottomNavigationBar: ListenableBuilder(
        listenable: audioLibrary,
        builder: (context, child) => PlayerBar(
          controller: audioLibrary,
          onOpenSource: () => Navigator.of(context).pop(),
        ),
      ),
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your collection',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Everything you save and download in one place.'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All music',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  tooltip: 'Scan phone',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: audioLibrary.isBusy
                      ? null
                      : audioLibrary.scanDeviceMusic,
                ),
              ],
            ),
            ListenableBuilder(
              listenable: audioLibrary,
              builder: (context, child) {
                if (audioLibrary.tracks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'No music found yet. Scan your phone to load tracks.',
                    ),
                  );
                }
                return Column(
                  children: audioLibrary.tracks
                      .map(
                        (track) =>
                            _TrackTile(track: track, controller: audioLibrary),
                      )
                      .toList(),
                );
              },
            ),
            _LibraryLink(
              icon: Icons.favorite_rounded,
              title: 'Liked songs',
              subtitle: 'Songs you marked as favourites',
              onTap: () => _openCollection(
                context,
                'Liked songs',
                Icons.favorite_rounded,
                includeAudioLibrary: true,
              ),
            ),
            _LibraryLink(
              icon: Icons.queue_music_rounded,
              title: 'Playlists',
              subtitle: 'Organise music for every moment',
              onTap: () => _openCollection(
                context,
                'Playlists',
                Icons.queue_music_rounded,
              ),
            ),
            _LibraryLink(
              icon: Icons.download_rounded,
              title: 'Downloads',
              subtitle: 'Music available offline',
              onTap: () =>
                  _openCollection(context, 'Downloads', Icons.download_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _openCollection(
    BuildContext context,
    String title,
    IconData icon, {
    bool includeAudioLibrary = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionPage(
          title: title,
          icon: icon,
          audioLibrary: includeAudioLibrary ? audioLibrary : null,
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        child: ListTile(
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
                  color: controller.isFavorite(track)
                      ? Colors.pinkAccent
                      : null,
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
      ),
    );
  }
}

class _LibraryLink extends StatelessWidget {
  const _LibraryLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
