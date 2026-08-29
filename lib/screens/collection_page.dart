import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../widgets/glass_surface.dart';
import '../widgets/music_visual.dart';
import '../widgets/player_bar.dart';
import '../widgets/track_actions.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    required this.title,
    required this.icon,
    this.audioLibrary,
    super.key,
  });

  final String title;
  final IconData icon;
  final AudioLibraryController? audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //     appBar: AppBar(title: Text(title)),
      //     bottomNavigationBar: audioLibrary == null
      //         ? null
      //         : ListenableBuilder(
      //             listenable: audioLibrary!,
      //             builder: (context, child) => PlayerBar(
      //               controller: audioLibrary!,
      //               onOpenSource: () {
      //                 if (Navigator.of(context).canPop()) {
      //                   Navigator.of(context).pop();
      //                 }
      //               },
      //             ),
      //           ),
      body: GlassBackground(
        accentListenable: audioLibrary,
        accentProvider: () => audioLibrary?.nowPlayingAccent,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (title == 'Artists' && audioLibrary != null) {
      return _ArtistsCollection(controller: audioLibrary!);
    }
    if (title == 'Albums' && audioLibrary != null) {
      return _AlbumsCollection(controller: audioLibrary!);
    }
    if (title == 'Playlists' && audioLibrary != null) {
      return _PlaylistCollection(controller: audioLibrary!);
    }
    if (title == 'Liked songs' && audioLibrary != null) {
      return ListenableBuilder(
        listenable: audioLibrary!,
        builder: (context, child) {
          final favorites = audioLibrary!.tracks
              .where(audioLibrary!.isFavorite)
              .toList();
          if (favorites.isEmpty) {
            return _EmptyCollection(icon: icon, title: title);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favorites.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${favorites.length} favorite${favorites.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                );
              }
              if (index == favorites.length + 1) {
                return const SizedBox(height: 24);
              }
              final track = favorites[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassSurface(
                  child: ListTile(
                    leading: TrackArtworkPreview(
                      title: track.name,
                      artwork: audioLibrary!.artworkFor(track),
                    ),
                    title: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove from favorites',
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.pinkAccent,
                      ),
                      onPressed: () => audioLibrary!.toggleFavorite(track),
                    ),
                    onTap: () => audioLibrary!.playTrack(
                      track,
                      source: TrackSource.likedSongs,
                    ),
                    onLongPress: () => TrackActions.show(
                      context,
                      controller: audioLibrary!,
                      track: track,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return _EmptyCollection(icon: icon, title: title);
  }
}

class _ArtistsCollection extends StatelessWidget {
  const _ArtistsCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final groups = controller.getCategorizedArtists();
        final artists = groups.values.expand((items) => items).toList();
        if (artists.isEmpty) {
          return const _EmptyCollection(
            icon: Icons.person_2_rounded,
            title: 'Artists',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassSurface(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      artist.artistName.isEmpty ? '?' : artist.artistName[0],
                    ),
                  ),
                  title: Text(artist.artistName),
                  subtitle: Text('${artist.trackCount} tracks'),
                  onTap: () =>
                      _showTracks(context, artist.artistName, artist.tracks),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTracks(BuildContext context, String name, List<AudioTrack> tracks) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GroupedTracksPage(
          title: name,
          tracks: tracks,
          controller: controller,
        ),
      ),
    );
  }
}

class _AlbumsCollection extends StatelessWidget {
  const _AlbumsCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final albums = <String, List<AudioTrack>>{};
    for (final track in controller.tracks) {
      final parts = track.path.split(RegExp(r'[/\\]'));
      final album = parts.length > 1 && parts[parts.length - 2].isNotEmpty
          ? parts[parts.length - 2]
          : 'Unknown album';
      albums.putIfAbsent(album, () => []).add(track);
    }
    final entries = albums.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    if (entries.isEmpty) {
      return const _EmptyCollection(icon: Icons.album_rounded, title: 'Albums');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final coverTrack = entry.value.first;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _GroupedTracksPage(
                title: entry.key,
                tracks: entry.value,
                controller: controller,
              ),
            ),
          ),
          child: GlassSurface(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                children: [
                  TrackArtworkPreview(
                    title: entry.key,
                    artwork: controller.artworkFor(coverTrack),
                    size: 148,
                  ),
                  Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${entry.value.length} tracks'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupedTracksPage extends StatelessWidget {
  const _GroupedTracksPage({
    required this.title,
    required this.tracks,
    required this.controller,
  });

  final String title;
  final List<AudioTrack> tracks;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ListTile(
            leading: TrackArtworkPreview(
              title: track.name,
              artwork: controller.artworkFor(track),
            ),
            title: Text(track.name),
            onTap: () => controller.playTrack(track),
            onLongPress: () => TrackActions.show(
              context,
              controller: controller,
              track: track,
            ),
          );
        },
      ),
    );
  }
}

class _PlaylistCollection extends StatelessWidget {
  const _PlaylistCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () =>
                    TrackActions.createPlaylist(context, controller),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New playlist'),
              ),
            ),
            const SizedBox(height: 12),
            if (controller.playlists.isEmpty)
              const _EmptyCollection(
                icon: Icons.queue_music_rounded,
                title: 'Playlists',
              )
            else
              ...controller.playlists.map(
                (playlist) => GlassSurface(
                  child: ListTile(
                    leading: const Icon(Icons.queue_music_rounded),
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.trackPaths.length} tracks'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PlaylistDetailPage(
                          controller: controller,
                          playlistId: playlist.id,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete playlist',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => controller.deletePlaylist(playlist),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaylistDetailPage extends StatelessWidget {
  const _PlaylistDetailPage({
    required this.controller,
    required this.playlistId,
  });

  final AudioLibraryController controller;
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final playlist = controller.playlistForId(playlistId);
        if (playlist == null) return const SizedBox.shrink();
        final tracks = controller.tracksForPlaylist(playlist);
        return Scaffold(
          appBar: AppBar(title: Text(playlist.name)),
          body: tracks.isEmpty
              ? const _EmptyCollection(
                  icon: Icons.queue_music_rounded,
                  title: 'Playlist is empty',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: TrackArtworkPreview(
                        title: track.name,
                        artwork: controller.artworkFor(track),
                      ),
                      title: Text(track.name),
                      onTap: () => controller.playTrack(
                        track,
                        source: TrackSource.playlist,
                      ),
                      onLongPress: () => TrackActions.show(
                        context,
                        controller: controller,
                        track: track,
                        currentPlaylist: playlist,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassSurface(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Nothing here yet. Add music to see it appear.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
