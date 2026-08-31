import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:music_player_app/audio/audio_effects.dart';

import '../audio/audio_effects_sheet.dart';

import '../audio/audio_library.dart';
import '../utils/responsive.dart';
import 'glass_surface.dart';
import 'music_visual.dart';
import 'track_actions.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({required this.controller, this.onOpenSource, super.key});

  final AudioLibraryController controller;
  final VoidCallback? onOpenSource;

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  @override
  void didUpdateWidget(covariant PlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.controller.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    final r = context.responsive;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.value(mobile: 8, tablet: 16, desktop: 24),
        0,
        r.value(mobile: 8, tablet: 16, desktop: 24),
        r.value(mobile: 12, tablet: 16, desktop: 20),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: r.value(mobile: 700, tablet: 900, desktop: 1200),
          ),
          child: GlassSurface(
            child: _MiniPlayer(
              controller: widget.controller,
              onOpenPlayer: () => _openMainPlayer(context),
            ),
          ),
        ),
      ),
    );
  }

  void _openMainPlayer(BuildContext context) {
    var closed = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close player',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _PlayerOverlay(
          controller: widget.controller,
          onOpenSource: widget.onOpenSource,
          onClose: () {
            if (closed) return;

            closed = true;

            Navigator.of(dialogContext).pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({required this.controller, required this.onOpenPlayer});

  final AudioLibraryController controller;
  final VoidCallback onOpenPlayer;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final track = widget.controller.currentTrack;

        if (track == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<Duration>(
          stream: widget.controller.player.positionStream,
          initialData: widget.controller.player.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration?>(
              stream: widget.controller.player.durationStream,
              initialData: widget.controller.player.duration,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                final total = duration.inMilliseconds;
                final progress = total <= 0
                    ? 0.0
                    : (position.inMilliseconds / total).clamp(0.0, 1.0);

                final accent =
                    widget.controller.nowPlayingAccent ??
                    Theme.of(context).colorScheme.primary;

                return Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: widget.onOpenPlayer,
                    borderRadius: BorderRadius.circular(35),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        color: accent.withValues(alpha: 0.20),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress,
                                child: ColoredBox(
                                  color: accent.withValues(alpha: 0.16),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              r.value(mobile: 12, tablet: 18, desktop: 22),
                              r.value(mobile: 7, tablet: 9, desktop: 11),
                              r.value(mobile: 12, tablet: 18, desktop: 22),
                              r.value(mobile: 10, tablet: 12, desktop: 14),
                            ),
                            child: Row(
                              children: [
                                TrackArtworkPreview(
                                  title: track.name,
                                  artwork: widget.controller.artworkFor(track),
                                  size: r.value(
                                    mobile: 50,
                                    tablet: 54,
                                    desktop: 58,
                                  ),
                                ),
                                SizedBox(
                                  width: r.value(
                                    mobile: 10,
                                    tablet: 13,
                                    desktop: 15,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r.font(14),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${_formatDuration(position)} / '
                                        '${_formatDuration(duration)}',
                                        style: TextStyle(
                                          fontSize: r.font(10),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.60),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Previous',
                                  iconSize: r.icon(23),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  onPressed: widget.controller.previousTrack,
                                  icon: const Icon(Icons.skip_previous_rounded),
                                ),
                                _PlaybackButton(
                                  controller: widget.controller,
                                  track: track,
                                ),
                                IconButton(
                                  tooltip: 'Next',
                                  iconSize: r.icon(23),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  onPressed: widget.controller.nextTrack,
                                  icon: const Icon(Icons.skip_next_rounded),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SizedBox(
                              height: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  child: ColoredBox(color: accent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlayerOverlay extends StatelessWidget {
  const _PlayerOverlay({
    required this.controller,
    required this.onClose,
    this.onOpenSource,
  });

  final AudioLibraryController controller;
  final VoidCallback onClose;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: r.value(mobile: 1, tablet: 0.82, desktop: 0.72),
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if (notification.extent <= 0.19) {
                      onClose();
                    }

                    return false;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.82,
                    minChildSize: 0.18,
                    maxChildSize: 0.94,
                    snap: true,
                    snapSizes: const [0.18, 0.82, 0.94],
                    builder: (context, scrollController) {
                      return _MainPlayerSheet(
                        controller: controller,
                        onOpenSource: onOpenSource,
                        onClose: onClose,
                        scrollController: scrollController,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainPlayerSheet extends StatelessWidget {
  const _MainPlayerSheet({
    required this.controller,
    required this.onClose,
    required this.scrollController,
    this.onOpenSource,
  });

  final AudioLibraryController controller;
  final VoidCallback onClose;
  final ScrollController scrollController;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final track = controller.currentTrack;
        final accent = controller.nowPlayingAccent;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        final baseColor = isDark
            ? const Color.fromARGB(248, 26, 27, 27)
            : const Color.fromARGB(255, 247, 248, 245);

        final backgroundColor = accent == null
            ? baseColor
            : Color.alphaBlend(
                accent.withValues(alpha: isDark ? 0.34 : 0.28),
                baseColor,
              );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: r.value(
              mobile: double.infinity,
              tablet: 760,
              desktop: 900,
            ),
            maxHeight: MediaQuery.sizeOf(context).height * 0.96,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(r.radius(28)),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    accent?.withValues(alpha: 0.28) ??
                    Colors.black.withValues(alpha: 0.24),
                blurRadius: accent == null ? 30 : 55,
                spreadRadius: accent == null ? 0 : 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ==========================================================
              // BLURRED ALBUM ART
              // ==========================================================

              if (track != null)
                Positioned.fill(
                  child: FutureBuilder<Uint8List?>(
                    future: controller.artworkFor(track),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;

                      if (bytes == null) {
                        return const SizedBox.shrink();
                      }

                      return ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 30,
                          sigmaY: 30,
                        ),
                        child: Transform.scale(
                          scale: 1.15,
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ==========================================================
              // AMBIENT OVERLAY
              // ==========================================================
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.26),
                ),
              ),

              // ==========================================================
              // TOP FADE
              // ==========================================================
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: isDark ? 0.38 : 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================================
              // ALBUM COLOR GRADIENT
              // ==========================================================
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.38, 0.58, 0.76, 1.0],
                      colors: [
                        Colors.transparent,
                        accent?.withValues(alpha: isDark ? 0.08 : 0.06) ??
                            Colors.transparent,
                        accent?.withValues(alpha: isDark ? 0.24 : 0.18) ??
                            Colors.transparent,
                        backgroundColor,
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================================
              // PLAYER CONTENT
              // ==========================================================
              SafeArea(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    r.value(mobile: 18, tablet: 32, desktop: 48),

                    r.value(mobile: 4, tablet: 10, desktop: 14),

                    r.value(mobile: 18, tablet: 32, desktop: 48),

                    r.value(mobile: 18, tablet: 28, desktop: 34),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // HANDLE
                      // ==================================================

                      Container(
                        width: r.value(mobile: 42, tablet: 48, desktop: 52),
                        height: r.scale(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      SizedBox(height: r.scale(2)),

                      // ==================================================
                      // TOP ICONS
                      // ==================================================
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Close player',
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: r.icon(27),
                            ),
                            onPressed: onClose,
                          ),

                          Expanded(
                            child: Center(
                              child: Text(
                                'Now playing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.font(14),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: 'Open source list',
                            icon: Icon(
                              Icons.list_rounded,
                              color: Colors.white,
                              size: r.icon(24),
                            ),
                            onPressed: onOpenSource,
                          ),
                        ],
                      ),

                      // ==================================================
                      // SPACE BEFORE CONTENT
                      // ==================================================
                      SizedBox(
                        height: r.value(mobile: 10, tablet: 14, desktop: 18),
                      ),

                      if (track == null)
                        Padding(
                          padding: EdgeInsets.all(r.scale(24)),
                          child: const Text(
                            'Choose a song from Library to start listening.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        _MainPlayerContent(
                          controller: controller,
                          track: track,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainPlayerContent extends StatelessWidget {
  const _MainPlayerContent({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack track;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    final artworkSize = r.value(mobile: 285, tablet: 390, desktop: 460);

    final accent = controller.nowPlayingAccent;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;

        if (velocity < -100) {
          controller.nextTrack();
        } else if (velocity > 100) {
          controller.previousTrack();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================================================
          // SQUARE ALBUM ART
          // ==================================================

          SizedBox.square(
            dimension: artworkSize,
            child: FutureBuilder<Uint8List?>(
              future: controller.artworkFor(track),
              builder: (context, snapshot) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r.radius(20)),
                    boxShadow: [
                      BoxShadow(
                        color:
                            accent?.withValues(alpha: 0.28) ??
                            Colors.black.withValues(alpha: 0.20),
                        blurRadius: accent == null ? 20 : 30,
                        spreadRadius: accent == null ? 0 : 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r.radius(20)),
                    child: SizedBox.expand(
                      child: FullPlayerAlbumArt(
                        title: track.name,
                        imageBytes: snapshot.data,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ==================================================
          // MORE SPACE BETWEEN ART & TITLE
          // ==================================================
          SizedBox(height: r.value(mobile: 18, tablet: 22, desktop: 26)),

          // ==================================================
          // SONG TITLE
          // ==================================================
          _ScrollingSongTitle(
            title: track.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.font(20),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              height: 1.15,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          SizedBox(height: r.scale(5)),

          Text(
            'Local library',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: r.font(12),
              fontWeight: FontWeight.w500,
            ),
          ),

          // ==================================================
          // MORE SPACE BEFORE PROGRESS
          // ==================================================
          SizedBox(height: r.value(mobile: 14, tablet: 17, desktop: 20)),

          _PlayerProgress(controller: controller),

          // ==================================================
          // MORE SPACE BEFORE SECONDARY CONTROLS
          // ==================================================
          SizedBox(height: r.value(mobile: 8, tablet: 11, desktop: 14)),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerSmallIconButton(
                icon: controller.isFavorite(track)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: controller.isFavorite(track)
                    ? Colors.pinkAccent
                    : Colors.white,
                tooltip: controller.isFavorite(track)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () {
                  controller.toggleFavorite(track);
                },
              ),

              _PlayerSmallIconButton(
                icon: Icons.playlist_add_rounded,
                tooltip: 'Add to playlist',
                onPressed: () {
                  TrackActions.showPlaylistPicker(
                    context,
                    controller: controller,
                    track: track,
                  );
                },
              ),

              _PlayerSmallIconButton(
                icon: Icons.shuffle_rounded,
                color: controller.shuffleEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.48),
                tooltip: 'Shuffle',
                onPressed: () {
                  controller.toggleShuffle(!controller.shuffleEnabled);
                },
              ),

              _PlayerSmallIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Audio effects',
                onPressed: () => _IntegratedAudioEffectsSheet.show(
                  context,
                  controller: controller,
                ),
              ),

              _PlayerSmallIconButton(
                icon: controller.repeatMode == AudioRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: controller.repeatMode != AudioRepeatMode.off
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.48),
                tooltip: _repeatLabel(controller.repeatMode),
                onPressed: controller.cycleRepeatMode,
              ),
            ],
          ),

          // ==================================================
          // BIGGER GAP BEFORE MAIN CONTROLS
          // ==================================================
          SizedBox(height: r.value(mobile: 18, tablet: 22, desktop: 26)),

          // ==================================================
          // MAIN PLAYBACK CONTROLS
          // ==================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous song',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(
                  Icons.skip_previous_rounded,
                  size: r.value(mobile: 32, tablet: 36, desktop: 40),
                  color: Colors.white,
                ),
                onPressed: controller.previousTrack,
              ),

              // MORE SPACE
              SizedBox(width: r.value(mobile: 30, tablet: 38, desktop: 46)),

              // ==================================================
              // PLAY BUTTON
              // ==================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: r.value(mobile: 60, tablet: 68, desktop: 74),
                height: r.value(mobile: 60, tablet: 68, desktop: 74),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent ?? Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (accent ?? Colors.white).withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: controller.isPlaying ? 'Pause' : 'Play',
                  padding: EdgeInsets.zero,
                  iconSize: r.value(mobile: 31, tablet: 35, desktop: 39),
                  icon: StreamBuilder<bool>(
                    stream: controller.player.playingStream,
                    initialData: controller.player.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        reverseDuration: const Duration(milliseconds: 140),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.82, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(isPlaying),
                          color: accent == null
                              ? Colors.black
                              : _contrastingColor(accent),
                        ),
                      );
                    },
                  ),
                  onPressed: controller.togglePlayback,
                ),
              ),

              // MORE SPACE
              SizedBox(width: r.value(mobile: 30, tablet: 38, desktop: 46)),

              IconButton(
                tooltip: 'Next song',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(
                  Icons.skip_next_rounded,
                  size: r.value(mobile: 32, tablet: 36, desktop: 40),
                  color: Colors.white,
                ),
                onPressed: controller.nextTrack,
              ),
            ],
          ),

          // Bottom breathing room
          SizedBox(height: r.value(mobile: 14, tablet: 18, desktop: 22)),
        ],
      ),
    );
  }

  Color _contrastingColor(Color color) {
    return color.computeLuminance() > 0.48 ? Colors.black : Colors.white;
  }

  String _repeatLabel(AudioRepeatMode mode) {
    return switch (mode) {
      AudioRepeatMode.off => 'Repeat off',
      AudioRepeatMode.all => 'Repeat all',
      AudioRepeatMode.one => 'Repeat current song',
    };
  }
}

// ==========================================================
// SCROLLING SONG TITLE
// ==========================================================

class _ScrollingSongTitle extends StatefulWidget {
  const _ScrollingSongTitle({required this.title, required this.style});

  final String title;
  final TextStyle style;

  @override
  State<_ScrollingSongTitle> createState() => _ScrollingSongTitleState();
}

class _ScrollingSongTitleState extends State<_ScrollingSongTitle> {
  final ScrollController _scrollController = ScrollController();

  Timer? _scrollTimer;

  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  @override
  void didUpdateWidget(covariant _ScrollingSongTitle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.title != widget.title) {
      _stopScrolling();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOverflow();
      });
    }
  }

  void _checkOverflow() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;

    if (maxScroll <= 0) {
      setState(() {
        _needsScrolling = false;
      });

      return;
    }

    setState(() {
      _needsScrolling = true;
    });

    _startScrolling();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();

    if (!_needsScrolling || !_scrollController.hasClients) {
      return;
    }

    _scrollTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;

      if (maxScroll <= 0) {
        return;
      }

      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: 2600 + (maxScroll * 7).round()),
        curve: Curves.linear,
      );

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );

      if (mounted) {
        _startScrolling();
      }
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (widget.style.fontSize ?? 20) * 1.45;

    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Text(
            widget.title,
            maxLines: 1,
            softWrap: false,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// SMALL PLAYER CONTROL
// ==========================================================

class _PlayerSmallIconButton extends StatelessWidget {
  const _PlayerSmallIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.all(r.scale(5)),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      iconSize: r.icon(20),
      color: color ?? Colors.white,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

// ==========================================================
// PLAYER PROGRESS
// ==========================================================

class _PlayerProgress extends StatelessWidget {
  const _PlayerProgress({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return StreamBuilder<Duration>(
      stream: controller.player.positionStream,
      initialData: controller.player.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: controller.player.durationStream,
          initialData: controller.player.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            final accent =
                controller.nowPlayingAccent ??
                Theme.of(context).colorScheme.primary;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Color.lerp(accent, Colors.black, 0.30),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
                    thumbColor: Color.lerp(accent, Colors.black, 0.18),
                    overlayColor: accent.withValues(alpha: 0.14),
                    trackHeight: r.value(mobile: 5, tablet: 6, desktop: 6),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: r.value(
                        mobile: 6,
                        tablet: 7,
                        desktop: 8,
                      ),
                    ),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds <= 0
                        ? 0.0
                        : (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    onChanged: duration.inMilliseconds <= 0
                        ? null
                        : (value) {
                            controller.player.seek(
                              Duration(
                                milliseconds: (duration.inMilliseconds * value)
                                    .round(),
                              ),
                            );
                          },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.value(mobile: 4, tablet: 16, desktop: 28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: r.font(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: r.font(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}

// ==========================================================
// FAVORITE BUTTON
// ==========================================================

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

// ==========================================================
// PLAYBACK BUTTON
// ==========================================================

class _PlaybackButton extends StatelessWidget {
  const _PlaybackButton({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack? track;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return IconButton(
        tooltip: 'Add music',
        icon: const Icon(Icons.library_add_rounded),
        onPressed: () => controller.importAudioFiles(),
      );
    }

    return StreamBuilder<bool>(
      stream: controller.player.playingStream,
      initialData: controller.player.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return IconButton(
          tooltip: isPlaying ? 'Pause' : 'Play',
          onPressed: controller.togglePlayback,
          icon: _AnimatedPlayPauseIcon(isPlaying: isPlaying),
        );
      },
    );
  }
}

// ==========================================================
// ANIMATED PLAY / PAUSE ICON
// ==========================================================

class _AnimatedPlayPauseIcon extends StatelessWidget {
  const _AnimatedPlayPauseIcon({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      child: Icon(
        isPlaying
            ? Icons.pause_circle_filled_rounded
            : Icons.play_circle_filled_rounded,
        key: ValueKey<bool>(isPlaying),
      ),
    );
  }
}

// ==========================================================
// MODERN AUDIO EFFECTS SHEET
// ==========================================================

class _IntegratedAudioEffectsSheet extends StatelessWidget {
  const _IntegratedAudioEffectsSheet({required this.controller, super.key});

  final AudioLibraryController controller;

  static Future<void> show(
    BuildContext context, {
    required AudioLibraryController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _IntegratedAudioEffectsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = context.responsive;

    return ListenableBuilder(
      listenable: controller.audioEngine,
      builder: (context, _) {
        final effects = controller.audioEngine.effects;
        final spatialEnabled = controller.spatialEnabled;
        final spatialDepth = controller.spatialDepth;
        final karaokeEnabled = controller.karaokeEnabled;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            r.value(mobile: 8, tablet: 18, desktop: 24),
            0,
            r.value(mobile: 8, tablet: 18, desktop: 24),
            8,
          ),
          child: Material(
            color: scheme.surface,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(r.radius(28)),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                r.value(mobile: 18, tablet: 24, desktop: 28),
                12,
                r.value(mobile: 18, tablet: 24, desktop: 28),
                22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Audio',
                          style: TextStyle(
                            fontSize: r.font(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reset',
                        onPressed: controller.audioEngine.reset,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _EffectSection(
                    title: 'Speed',
                    value: '${effects.speed.toStringAsFixed(2)}×',
                    child: Slider(
                      value: effects.speed,
                      min: .5,
                      max: 2,
                      divisions: 30,
                      onChanged: controller.audioEngine.setSpeed,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _EffectSection(
                    title: 'Pitch',
                    value:
                        '${effects.pitchSemitones >= 0 ? '+' : ''}'
                        '${effects.pitchSemitones.toStringAsFixed(1)} st',
                    child: Slider(
                      value: effects.pitchSemitones,
                      min: -12,
                      max: 12,
                      divisions: 48,
                      onChanged: controller.audioEngine.setPitch,
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 28),

                  _EqSection(
                    effects: effects,
                    onChanged: (index, value) {
                      controller.audioEngine.setEqBand(index, value);
                    },
                  ),

                  const SizedBox(height: 8),

                  _CleanEffectRow(
                    icon: Icons.spatial_audio_rounded,
                    title: 'Spatial audio',
                    subtitle: spatialEnabled
                        ? 'Immersion ${(spatialDepth * 100).round()}%'
                        : 'Off',
                    value: spatialEnabled,
                    onChanged: (enabled) {
                      controller.audioEngine.setSpatialEnabled(enabled);
                      controller.audioEngine.setSpatialDepth(spatialDepth);
                    },
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: spatialEnabled
                        ? Padding(
                            padding: const EdgeInsets.only(left: 52, right: 4),
                            child: Slider(
                              value: spatialDepth,
                              min: 0,
                              max: 1,
                              divisions: 20,
                              onChanged: (depth) {
                                controller.audioEngine.setSpatialDepth(depth);
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  _CleanEffectRow(
                    icon: Icons.mic_off_rounded,
                    title: 'Karaoke',
                    subtitle: karaokeEnabled
                        ? 'Vocal reduction on'
                        : 'Reduce centered vocals',
                    value: karaokeEnabled,
                    onChanged: controller.audioEngine.setKaraokeEnabled,
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

class _EffectSection extends StatelessWidget {
  const _EffectSection({
    required this.title,
    required this.value,
    required this.child,
  });

  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

class _EqSection extends StatelessWidget {
  const _EqSection({required this.effects, required this.onChanged});

  final AudioEffects effects;
  final void Function(int index, double value) onChanged;

  static const List<String> _labels = [
    '60',
    '120',
    '250',
    '500',
    '1k',
    '2k',
    '4k',
    '8k',
    '12k',
    '16k',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '10-band EQ',
                style: TextStyle(
                  fontSize: r.font(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '±12 dB',
              style: TextStyle(
                fontSize: r.font(12),
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(effects.eq.length, (index) {
              return Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: effects.eq[index].clamp(-12.0, 12.0),
                          min: -12.0,
                          max: 12.0,
                          divisions: 48,
                          onChanged: (value) => onChanged(index, value),
                        ),
                      ),
                    ),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: r.font(9),
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: .60),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CleanEffectRow extends StatelessWidget {
  const _CleanEffectRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r.radius(18)),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: r.scale(8)),
          child: Row(
            children: [
              Container(
                width: r.scale(42),
                height: r.scale(42),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(r.radius(14)),
                ),
                child: Icon(icon, size: r.icon(20)),
              ),
              SizedBox(width: r.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.font(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: r.font(11),
                        color: scheme.onSurface.withValues(alpha: .52),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
