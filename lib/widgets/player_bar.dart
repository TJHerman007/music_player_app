import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import 'glass_surface.dart';
import 'music_visual.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({required this.controller, this.onOpenSource, super.key});

  final AudioLibraryController controller;
  final VoidCallback? onOpenSource;

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.controller.currentTrack;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, _isExpanded ? 12 : 24),
      child: GlassSurface(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isExpanded
                  ? _ExpandedHeader(
                      controller: widget.controller,
                      onOpenSource: widget.onOpenSource,
                      onClose: () => setState(() => _isExpanded = false),
                    )
                  : _CollapsedPlayer(
                      controller: widget.controller,
                      onExpand: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
              if (_isExpanded)
                _ExpandedPlayer(controller: widget.controller, track: track),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedPlayer extends StatelessWidget {
  const _CollapsedPlayer({required this.controller, required this.onExpand});

  final AudioLibraryController controller;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onExpand,
      leading: Icon(
        track == null ? Icons.music_note_outlined : Icons.graphic_eq_rounded,
      ),
      title: Text(
        track?.name ?? 'Nothing playing',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(track == null ? 'Tap to add music' : 'Tap to open player'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FavoriteButton(controller: controller, track: track),
          IconButton(
            tooltip: 'Next song',
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: track == null ? null : controller.nextTrack,
          ),
          _PlaybackButton(controller: controller, track: track),
        ],
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader({
    required this.controller,
    required this.onClose,
    this.onOpenSource,
  });

  final AudioLibraryController controller;
  final VoidCallback onClose;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Now playing'),
      subtitle: Text(
        controller.currentTrack?.name ?? 'Nothing playing',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        tooltip: 'Open source list',
        icon: const Icon(Icons.list_rounded),
        onPressed: onOpenSource,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FavoriteButton(
            controller: controller,
            track: controller.currentTrack,
          ),
          IconButton(
            tooltip: 'Close player',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack? track;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Choose a song from Library to start listening.'),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) {
          controller.nextTrack();
        } else if (velocity > 100) {
          controller.previousTrack();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            const SizedBox(height: 4),
            ThreeDAlbumArt(title: track!.name),
            const SizedBox(height: 18),
            Text(
              track!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Duration>(
              stream: controller.player.positionStream,
              initialData: controller.player.position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: controller.player.durationStream,
                  initialData: controller.player.duration,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final maximum = duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0;
                    final value = position.inMilliseconds
                        .clamp(0, maximum.toInt())
                        .toDouble();
                    return Column(
                      children: [
                        Slider(
                          value: value,
                          max: maximum,
                          onChanged: duration == Duration.zero
                              ? null
                              : (value) => controller.player.seek(
                                  Duration(milliseconds: value.round()),
                                ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Shuffle',
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: controller.shuffleEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () =>
                      controller.toggleShuffle(!controller.shuffleEnabled),
                ),
                IconButton(
                  tooltip: _repeatLabel(controller.repeatMode),
                  icon: Icon(
                    controller.repeatMode == AudioRepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: controller.repeatMode != AudioRepeatMode.off
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: controller.cycleRepeatMode,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous song',
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: controller.previousTrack,
                ),
                IconButton(
                  tooltip: controller.isPlaying ? 'Pause' : 'Play',
                  iconSize: 48,
                  icon: Icon(
                    controller.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  onPressed: controller.togglePlayback,
                ),
                IconButton(
                  tooltip: 'Next song',
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: controller.nextTrack,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _repeatLabel(AudioRepeatMode mode) {
    return switch (mode) {
      AudioRepeatMode.off => 'Repeat off',
      AudioRepeatMode.all => 'Repeat all',
      AudioRepeatMode.one => 'Repeat current song',
    };
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack? track;

  @override
  Widget build(BuildContext context) {
    final isFavorite = track != null && controller.isFavorite(track!);
    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Colors.pinkAccent : null,
      ),
      onPressed: track == null ? null : () => controller.toggleFavorite(track!),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  const _PlaybackButton({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack? track;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: track == null
          ? 'Add music'
          : controller.isPlaying
          ? 'Pause'
          : 'Play',
      icon: Icon(
        track == null
            ? Icons.library_add_rounded
            : controller.isPlaying
            ? Icons.pause_circle_filled_rounded
            : Icons.play_circle_filled_rounded,
      ),
      onPressed: track == null
          ? () => controller.importAudioFiles()
          : controller.togglePlayback,
    );
  }
}
