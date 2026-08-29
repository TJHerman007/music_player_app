import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
    final track = widget.controller.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentTrack = widget.controller.currentTrack;

        if (currentTrack == null) {
          return const SizedBox.shrink();
        }

        final accent = widget.controller.nowPlayingAccent;

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onOpenPlayer,
            borderRadius: BorderRadius.circular(35),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: accent?.withValues(alpha: 0.24),
                border: accent == null
                    ? null
                    : Border.all(
                        color: accent.withValues(alpha: 0.30),
                        width: 1,
                      ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.value(mobile: 14, tablet: 20, desktop: 24),
                  vertical: r.value(mobile: 8, tablet: 10, desktop: 12),
                ),
                child: Row(
                  children: [
                    TrackArtworkPreview(
                      title: currentTrack.name,
                      artwork: widget.controller.artworkFor(currentTrack),
                      size: r.value(mobile: 52, tablet: 56, desktop: 60),
                    ),

                    SizedBox(
                      width: r.value(mobile: 12, tablet: 14, desktop: 16),
                    ),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: r.font(15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Tap to open player',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: r.font(12)),
                          ),
                        ],
                      ),
                    ),

                    _FavoriteButton(
                      controller: widget.controller,
                      track: currentTrack,
                    ),

                    IconButton(
                      tooltip: 'Next song',
                      iconSize: r.icon(27),
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: widget.controller.nextTrack,
                    ),

                    _PlaybackButton(
                      controller: widget.controller,
                      track: currentTrack,
                    ),

                    IconButton(
                      tooltip: 'Add to playlist',
                      icon: const Icon(Icons.playlist_add_rounded),
                      onPressed: () => TrackActions.showPlaylistPicker(
                        context,
                        controller: widget.controller,
                        track: currentTrack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

            final maximum = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;

            final progress =
                (position.inMilliseconds.clamp(0, maximum.toInt()).toDouble() /
                        maximum)
                    .clamp(0.0, 1.0);

            final accent =
                controller.nowPlayingAccent ??
                Theme.of(context).colorScheme.primary;

            return Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;

                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );

                    final width = box.size.width;

                    final newProgress = (localPosition.dx / width).clamp(
                      0.0,
                      1.0,
                    );

                    controller.player.seek(
                      Duration(milliseconds: (maximum * newProgress).round()),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: r.scale(8)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 7,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                width: constraints.maxWidth * progress,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
