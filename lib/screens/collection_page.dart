import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../widgets/glass_surface.dart';
import '../widgets/player_bar.dart';

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
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: audioLibrary == null
          ? null
          : ListenableBuilder(
              listenable: audioLibrary!,
              builder: (context, child) => PlayerBar(
                controller: audioLibrary!,
                onOpenSource: () => Navigator.of(context).pop(),
              ),
            ),
      body: GlassBackground(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${favorites.length} favorite${favorites.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...favorites.map(
                (track) => GlassSurface(
                  child: ListTile(
                    leading: const Icon(Icons.music_note_rounded),
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
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return _EmptyCollection(icon: icon, title: title);
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
