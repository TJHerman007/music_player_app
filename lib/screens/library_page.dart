import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';
import '../widgets/music_visual.dart';
import '../widgets/player_bar.dart';
import '../widgets/track_actions.dart';
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
          onOpenSource: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: GlassBackground(
        accentListenable: audioLibrary,
        accentProvider: () => audioLibrary.nowPlayingAccent,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your collection',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Everything you save and download in one place.',
                    ),
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
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: audioLibrary,
              builder: (context, child) {
                if (audioLibrary.tracks.isEmpty) {
                  return const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'No music found yet. Scan your phone to load tracks.',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: audioLibrary.tracks.length,
                    itemBuilder: (context, index) => _TrackTile(
                      track: audioLibrary.tracks[index],
                      controller: audioLibrary,
                    ),
                  ),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
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
                        includeAudioLibrary: true,
                      ),
                    ),
                    _LibraryLink(
                      icon: Icons.download_rounded,
                      title: 'Downloads',
                      subtitle: 'Music available offline',
                      onTap: () => _openCollection(
                        context,
                        'Downloads',
                        Icons.download_rounded,
                      ),
                    ),
                  ],
                ),
              ),
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
    final colors = Theme.of(context).colorScheme;
    final isSelected = controller.currentTrack?.path == track.path;
    final isPlaying = isSelected && controller.isPlaying;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.72)
              : colors.surface.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.62)
                : colors.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              controller.playTrack(track, source: TrackSource.library);
            },
            onLongPress: () => TrackActions.show(
              context,
              controller: controller,
              track: track,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  TrackArtworkPreview(
                    title: track.name,
                    artwork: controller.artworkFor(track),
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPlaying ? 'Playing now' : 'Tap to play',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: controller.isFavorite(track)
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    icon: Icon(
                      controller.isFavorite(track)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: controller.isFavorite(track)
                          ? Colors.pinkAccent
                          : colors.onSurfaceVariant,
                    ),
                    onPressed: () => controller.toggleFavorite(track),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isPlaying
                        ? const NowPlayingIndicator(key: ValueKey('playing'))
                        : Icon(
                            isSelected
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            key: ValueKey(isSelected),
                            color: colors.primary,
                          ),
                  ),
                ],
              ),
            ),
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
