import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../audio/audio_library.dart';

class TrackActions {
  const TrackActions._();

  static Future<void> show(
    BuildContext context, {
    required AudioLibraryController controller,
    required AudioTrack track,
    AudioPlaylist? currentPlaylist,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.pop(sheetContext);
                showPlaylistPicker(
                  context,
                  controller: controller,
                  track: track,
                );
              },
            ),
            if (currentPlaylist != null)
              ListTile(
                leading: const Icon(Icons.playlist_remove_rounded),
                title: const Text('Remove from this playlist'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await controller.removeFromPlaylist(track, currentPlaylist);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove track'),
              onTap: () async {
                Navigator.pop(sheetContext);
                controller.removeTrack(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(sheetContext);
                Share.share(track.path, subject: track.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Track details'),
              onTap: () {
                Navigator.pop(sheetContext);
                showDetails(context, track);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showPlaylistPicker(
    BuildContext context, {
    required AudioLibraryController controller,
    required AudioTrack track,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Create playlist'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await createPlaylist(context, controller);
                final playlist = controller.playlists.isEmpty
                    ? null
                    : controller.playlists.last;
                if (playlist != null) {
                  await controller.addToPlaylist(track, playlist);
                }
              },
            ),
            ...controller.playlists.map(
              (playlist) => ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(playlist.name),
                subtitle: Text('${playlist.trackPaths.length} tracks'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await controller.addToPlaylist(track, playlist);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> createPlaylist(
    BuildContext context,
    AudioLibraryController controller,
  ) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name != null) await controller.createPlaylist(name);
  }

  static Future<void> showDetails(BuildContext context, AudioTrack track) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(track.name),
        content: SelectableText(track.path),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
