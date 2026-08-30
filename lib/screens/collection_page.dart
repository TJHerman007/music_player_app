import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../widgets/glass_surface.dart';
import '../widgets/music_visual.dart';
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
      backgroundColor: _background(context),
      body: GlassBackground(
        accentListenable: audioLibrary,
        accentProvider: () => audioLibrary?.nowPlayingAccent,
        child: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Color _background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF08090D)
        : Theme.of(context).colorScheme.surface;
  }

  Widget _buildBody(BuildContext context) {
    if (audioLibrary == null) {
      return _EmptyCollection(icon: icon, title: title);
    }

    if (title == 'Artists') {
      return _ArtistsCollection(controller: audioLibrary!);
    }

    if (title == 'Albums') {
      return _AlbumsCollection(controller: audioLibrary!);
    }

    if (title == 'Playlists') {
      return _PlaylistCollection(controller: audioLibrary!);
    }

    if (title == 'Liked songs') {
      return _LikedSongsCollection(controller: audioLibrary!);
    }

    return _EmptyCollection(icon: icon, title: title);
  }
}

// ============================================================================
// CLEAN COLLECTIONS DESIGN
// ============================================================================

class _CollectionColors {
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
}

// ============================================================================
// COLLECTION PAGE HEADER
// ============================================================================

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final primary = _CollectionColors.primary(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 28,
        compact ? 14 : 22,
        compact ? 18 : 28,
        compact ? 18 : 22,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).maybePop(),
              splashColor: primary.withValues(alpha: 0.08),
              highlightColor: primary.withValues(alpha: 0.04),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _CollectionColors.text(context),
                    fontSize: compact ? 25 : 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _CollectionColors.secondary(context),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: compact ? 21 : 23, color: primary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ARTISTS
// ============================================================================

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

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CollectionHeader(
                title: 'Artists',
                subtitle:
                    '${artists.length} ${artists.length == 1 ? 'artist' : 'artists'}',
                icon: Icons.person_2_rounded,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverList.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _ArtistTile(
                      artist: artist,
                      controller: controller,
                      onTap: () => _openTracks(
                        context,
                        artist.artistName,
                        artist.tracks,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openTracks(
    BuildContext context,
    String title,
    List<AudioTrack> tracks,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GroupedTracksPage(
          title: title,
          tracks: tracks,
          controller: controller,
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({
    required this.artist,
    required this.controller,
    required this.onTap,
  });

  final ArtistGroup artist;
  final AudioLibraryController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = _CollectionColors.primary(context);
    final selected =
        controller.currentTrack != null &&
        artist.tracks.any(
          (track) => track.path == controller.currentTrack!.path,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: primary.withValues(alpha: 0.07),
        highlightColor: primary.withValues(alpha: 0.035),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: selected ? 0.16 : 0.08),
                ),
                child: Center(
                  child: Text(
                    artist.artistName.isEmpty
                        ? '#'
                        : artist.artistName[0].toUpperCase(),
                    style: TextStyle(
                      color: primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CollectionColors.text(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artist.trackCount} ${artist.trackCount == 1 ? 'song' : 'songs'}',
                      style: TextStyle(
                        color: _CollectionColors.secondary(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: _CollectionColors.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ALBUMS — REFERENCE DESIGN
// ============================================================================

class _AlbumsCollection extends StatelessWidget {
  const _AlbumsCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // KEEP EXISTING ALBUM LOGIC: group from AudioTrack.album metadata.
        final albums = <String, List<AudioTrack>>{};

        for (final track in controller.tracks) {
          final album = track.album.trim().isEmpty
              ? 'Unknown album'
              : track.album.trim();

          albums.putIfAbsent(album, () => <AudioTrack>[]).add(track);
        }

        final entries = albums.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

        if (entries.isEmpty) {
          return const _EmptyCollection(
            icon: Icons.album_rounded,
            title: 'Albums',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final columns = width >= 1200
                ? 4
                : width >= 820
                ? 4
                : width >= 560
                ? 3
                : 2;

            final horizontalPadding = width >= 900 ? 30.0 : 18.0;
            final gap = width >= 900 ? 20.0 : 14.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      width >= 600 ? 22 : 14,
                      horizontalPadding,
                      8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Albums',
                                style: TextStyle(
                                  color: _CollectionColors.text(context),
                                  fontSize: width >= 900 ? 23 : 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.55,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entries.length} ${entries.length == 1 ? 'album' : 'albums'}',
                                style: TextStyle(
                                  color: _CollectionColors.secondary(context),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.grid_view_rounded,
                          size: 24,
                          color: _CollectionColors.primary(context),
                        ),
                        const SizedBox(width: 18),
                        Icon(
                          Icons.tune_rounded,
                          size: 23,
                          color: _CollectionColors.muted(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    120,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = entries[index];

                      return _AlbumCard(
                        albumName: entry.key,
                        tracks: entry.value,
                        controller: controller,
                      );
                    }, childCount: entries.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: width >= 900 ? 25 : 22,
                      childAspectRatio: width >= 900 ? 0.77 : 0.72,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.albumName,
    required this.tracks,
    required this.controller,
  });

  final String albumName;
  final List<AudioTrack> tracks;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final coverTrack = tracks.first;
    final width = MediaQuery.sizeOf(context).width;
    final radius = width >= 600 ? 18.0 : 15.0;
    final colors = Theme.of(context).colorScheme;

    // Deliberately NO GlassSurface and NO border.
    // This is what removes the black collection "window".
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        splashColor: colors.primary.withValues(alpha: 0.06),
        highlightColor: colors.primary.withValues(alpha: 0.025),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _GroupedTracksPage(
                title: albumName,
                tracks: tracks,
                controller: controller,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Soft neutral/adaptive shadow under the artwork.
                    Positioned(
                      left: 9,
                      right: 9,
                      bottom: -3,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.16),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: TrackArtworkPreview(
                          title: albumName,
                          artwork: controller.artworkFor(coverTrack),
                          size: 260,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                albumName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: width >= 900 ? 15 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _albumArtist(tracks),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.57),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                maxLines: 1,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.42),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _albumArtist(List<AudioTrack> tracks) {
    for (final track in tracks) {
      final artist = track.artist.trim();
      if (artist.isNotEmpty && artist.toLowerCase() != 'unknown') {
        return artist;
      }
    }
    return 'Unknown artist';
  }
}

// ============================================================================
// LIKED SONGS
// ============================================================================

class _LikedSongsCollection extends StatelessWidget {
  const _LikedSongsCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final favorites = controller.tracks
            .where(controller.isFavorite)
            .toList();

        if (favorites.isEmpty) {
          return const _EmptyCollection(
            icon: Icons.favorite_rounded,
            title: 'Liked songs',
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CollectionHeader(
                title: 'Liked songs',
                subtitle:
                    '${favorites.length} ${favorites.length == 1 ? 'favorite' : 'favorites'}',
                icon: Icons.favorite_rounded,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverList.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _TrackTile(
                      track: favorites[index],
                      controller: controller,
                      showFavorite: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// CLEAN TRACK TILE
// ============================================================================

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.controller,
    this.showFavorite = false,
  });

  final AudioTrack track;
  final AudioLibraryController controller;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final current = controller.currentTrack?.path == track.path;
    final playing = current && controller.isPlaying;
    final primary = _CollectionColors.primary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        splashColor: primary.withValues(alpha: 0.06),
        highlightColor: primary.withValues(alpha: 0.025),
        onTap: () => controller.playTrack(
          track,
          source: showFavorite ? TrackSource.likedSongs : TrackSource.library,
        ),
        onLongPress: () =>
            TrackActions.show(context, controller: controller, track: track),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: TrackArtworkPreview(
                  title: track.name,
                  artwork: controller.artworkFor(track),
                  size: 54,
                ),
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
                      style: TextStyle(
                        color: _CollectionColors.text(context),
                        fontSize: 14.5,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CollectionColors.secondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showFavorite)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.favorite_rounded, size: 19, color: primary),
                  onPressed: () => controller.toggleFavorite(track),
                ),
              SizedBox(
                width: 30,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: playing
                      ? const NowPlayingIndicator(key: ValueKey('playing'))
                      : Icon(
                          Icons.play_circle_outline_rounded,
                          key: const ValueKey('play'),
                          size: 22,
                          color: primary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GROUPED TRACK PAGE
// ============================================================================

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GlassBackground(
        accentListenable: controller,
        accentProvider: () => controller.nowPlayingAccent,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
                  child: Text(
                    '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: _CollectionColors.secondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                sliver: SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _TrackTile(
                        track: tracks[index],
                        controller: controller,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PLAYLISTS
// ============================================================================

class _PlaylistCollection extends StatelessWidget {
  const _PlaylistCollection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CollectionHeader(
                title: 'Playlists',
                subtitle:
                    '${controller.playlists.length} ${controller.playlists.length == 1 ? 'playlist' : 'playlists'}',
                icon: Icons.queue_music_rounded,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _CreatePlaylistTile(
                  onTap: () => TrackActions.createPlaylist(context, controller),
                ),
              ),
            ),
            if (controller.playlists.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCollection(
                  icon: Icons.queue_music_rounded,
                  title: 'Playlists',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                sliver: SliverList.builder(
                  itemCount: controller.playlists.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _PlaylistTile(
                        playlist: controller.playlists[index],
                        controller: controller,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CreatePlaylistTile extends StatelessWidget {
  const _CreatePlaylistTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = _CollectionColors.primary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        splashColor: primary.withValues(alpha: 0.06),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.10),
                ),
                child: Icon(Icons.add_rounded, color: primary, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create new playlist',
                      style: TextStyle(
                        color: _CollectionColors.text(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Build a collection from your songs',
                      style: TextStyle(
                        color: _CollectionColors.secondary(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _CollectionColors.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.controller});

  final AudioPlaylist playlist;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final tracks = controller.tracksForPlaylist(playlist);
    final primary = _CollectionColors.primary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        splashColor: primary.withValues(alpha: 0.06),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PlaylistDetailPage(
                controller: controller,
                playlistId: playlist.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            children: [
              _PlaylistArtwork(
                controller: controller,
                playlist: playlist,
                tracks: tracks,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CollectionColors.text(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.trackPaths.length} ${playlist.trackPaths.length == 1 ? 'song' : 'songs'}',
                      style: TextStyle(
                        color: _CollectionColors.secondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Playlist options',
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: _CollectionColors.muted(context),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    controller.deletePlaylist(playlist);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete playlist'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistArtwork extends StatelessWidget {
  const _PlaylistArtwork({
    required this.controller,
    required this.playlist,
    required this.tracks,
  });

  final AudioLibraryController controller;
  final AudioPlaylist playlist;
  final List<AudioTrack> tracks;

  @override
  Widget build(BuildContext context) {
    if (tracks.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TrackArtworkPreview(
          title: playlist.name,
          artwork: controller.artworkFor(tracks.first),
          size: 56,
        ),
      );
    }

    final primary = _CollectionColors.primary(context);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: primary.withValues(alpha: 0.09),
      ),
      child: Icon(Icons.queue_music_rounded, color: primary, size: 25),
    );
  }
}

// ============================================================================
// PLAYLIST DETAIL
// ============================================================================

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

        if (playlist == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const SizedBox.shrink(),
          );
        }

        final tracks = controller.tracksForPlaylist(playlist);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: GlassBackground(
            accentListenable: controller,
            accentProvider: () => controller.nowPlayingAccent,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (tracks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCollection(
                        icon: Icons.queue_music_rounded,
                        title: 'Playlist is empty',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                      sliver: SliverList.builder(
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PlaylistTrackTile(
                              track: tracks[index],
                              playlist: playlist,
                              controller: controller,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PLAYLIST TRACK TILE
// ============================================================================

class _PlaylistTrackTile extends StatelessWidget {
  const _PlaylistTrackTile({
    required this.track,
    required this.playlist,
    required this.controller,
  });

  final AudioTrack track;
  final AudioPlaylist playlist;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        controller.currentTrack?.path == track.path && controller.isPlaying;
    final primary = _CollectionColors.primary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        splashColor: primary.withValues(alpha: 0.06),
        onTap: () => controller.playTrack(track, source: TrackSource.playlist),
        onLongPress: () => TrackActions.show(
          context,
          controller: controller,
          track: track,
          currentPlaylist: playlist,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: TrackArtworkPreview(
                  title: track.name,
                  artwork: controller.artworkFor(track),
                  size: 54,
                ),
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
                      style: TextStyle(
                        color: _CollectionColors.text(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CollectionColors.secondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isPlaying
                    ? const SizedBox(
                        key: ValueKey('playing'),
                        width: 30,
                        child: NowPlayingIndicator(),
                      )
                    : Icon(
                        Icons.play_circle_outline_rounded,
                        key: const ValueKey('play'),
                        color: primary,
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final primary = _CollectionColors.primary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.09),
              ),
              child: Icon(icon, size: 31, color: primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CollectionColors.text(context),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Nothing here yet. Add music to see it appear.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CollectionColors.secondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
