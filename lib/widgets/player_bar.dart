import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:music_player_app/audio/equalizer_page.dart';
import 'package:music_player_app/utils/animated_wave_progress_bar.dart';

import '../audio/audio_engine.dart';
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
  bool _playerOpen = false;

  Future<void> _openPlayer(BuildContext context) async {
    if (_playerOpen) return;
    setState(() => _playerOpen = true);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close player',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return _PlayerOverlay(
            controller: widget.controller,
            onClose: () => Navigator.of(dialogContext).pop(),
            onOpenSource: widget.onOpenSource,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      );
    } finally {
      if (mounted) setState(() => _playerOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playerOpen) return const SizedBox.shrink();

    final r = context.responsive;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.currentTrack == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            r.value(mobile: 8, tablet: 16, desktop: 24),
            0,
            r.value(mobile: 8, tablet: 16, desktop: 24),
            r.value(mobile: 12, tablet: 16, desktop: 20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: r.value(mobile: 700, tablet: 900, desktop: 1200),
            ),
            child: _MiniPlayer(
              controller: widget.controller,
              onOpenPlayer: () => _openPlayer(context),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.controller, required this.onOpenPlayer});

  final AudioLibraryController controller;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final track = controller.currentTrack;
        if (track == null) return const SizedBox.shrink();

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
                final max = duration.inMilliseconds;
                final progress = max > 0
                    ? (position.inMilliseconds / max).clamp(0.0, 1.0)
                    : 0.0;
                final accent =
                    controller.nowPlayingAccent ??
                    Theme.of(context).colorScheme.primary;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(r.radius(28)),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent,
                                    Color.lerp(
                                          accent,
                                          Theme.of(context).colorScheme.primary,
                                          0.55,
                                        ) ??
                                        accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onOpenPlayer,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.value(
                                mobile: 10,
                                tablet: 16,
                                desktop: 20,
                              ),
                              vertical: r.value(
                                mobile: 7,
                                tablet: 9,
                                desktop: 11,
                              ),
                            ),
                            child: Row(
                              children: [
                                TrackArtworkPreview(
                                  title: track.name,
                                  artwork: controller.artworkFor(track),
                                  size: r.value(
                                    mobile: 50,
                                    tablet: 54,
                                    desktop: 58,
                                  ),
                                ),
                                SizedBox(width: r.scale(10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        track.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r.font(14),
                                          fontWeight: FontWeight.w700,
                                          color: progress > .58
                                              ? Colors.white
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                        ),
                                      ),
                                      Text(
                                        track.artist.trim().isEmpty ||
                                                track.artist == 'Unknown'
                                            ? 'Local library'
                                            : track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: r.font(10),
                                          color: progress > .58
                                              ? Colors.white.withValues(
                                                  alpha: .78,
                                                )
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: .60),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _MiniButton(
                                  icon: Icons.skip_previous_rounded,
                                  onPressed: controller.previousTrack,
                                  color: progress > .58 ? Colors.white : null,
                                ),
                                _MiniPlayButton(
                                  controller: controller,
                                  foreground: progress > .58
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                _MiniButton(
                                  icon: Icons.skip_next_rounded,
                                  onPressed: controller.nextTrack,
                                  color: progress > .58 ? Colors.white : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onPressed, this.color});

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      iconSize: r.icon(22),
      onPressed: onPressed,
      color: color,
      icon: Icon(icon),
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton({required this.controller, this.foreground});

  final AudioLibraryController controller;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return StreamBuilder<bool>(
      stream: controller.player.playingStream,
      initialData: controller.player.playing,
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;

        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          iconSize: r.icon(28),
          onPressed: controller.togglePlayback,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              key: ValueKey(playing),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerOverlay extends StatefulWidget {
  const _PlayerOverlay({
    required this.controller,
    required this.onClose,
    this.onOpenSource,
  });

  final AudioLibraryController controller;
  final VoidCallback onClose;
  final VoidCallback? onOpenSource;

  @override
  State<_PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<_PlayerOverlay> {
  int _artworkDirection = 1;
  bool _changingTrack = false;

  Offset? _pointerDown;
  bool _horizontalSwipe = false;

  void _next() {
    _changeTrack(forward: true);
  }

  void _previous() {
    _changeTrack(forward: false);
  }

  void _changeTrack({required bool forward}) {
    if (_changingTrack || widget.controller.tracks.length < 2) return;

    setState(() {
      _artworkDirection = forward ? 1 : -1;
      _changingTrack = true;
    });

    unawaited(
      (forward
              ? widget.controller.nextTrack()
              : widget.controller.previousTrack())
          .whenComplete(() {
            if (mounted) {
              setState(() => _changingTrack = false);
            }
          }),
    );
  }

  Future<void> _openMore(BuildContext context, AudioTrack track) async {
    final action = await showModalBottomSheet<_MoreAction>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const _MoreSheet(),
    );

    if (!mounted || action == null) return;

    if (action == _MoreAction.effects) {
      await _AudioEffectsSheet.show(context, controller: widget.controller);
    } else if (action == _MoreAction.trackActions) {
      await TrackActions.show(
        context,
        controller: widget.controller,
        track: track,
      );
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDown = event.position;
    _horizontalSwipe = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final start = _pointerDown;
    if (start == null || _horizontalSwipe) return;

    final dx = event.position.dx - start.dx;
    final dy = event.position.dy - start.dy;

    if (dx.abs() > 28 && dx.abs() > dy.abs() * 1.25) {
      _horizontalSwipe = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerDown;
    _pointerDown = null;

    if (start == null || !_horizontalSwipe) return;

    final dx = event.position.dx - start.dx;
    _horizontalSwipe = false;

    if (dx < -72) {
      _next();
    } else if (dx > 72) {
      _previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape =
                MediaQuery.orientationOf(context) == Orientation.landscape;

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: (_) {
                _pointerDown = null;
                _horizontalSwipe = false;
              },
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent <= 0.205 && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) widget.onClose();
                    });
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: 0.82,
                  minChildSize: 0.18,
                  maxChildSize: 0.94,
                  snap: true,
                  snapSizes: const [0.18, 0.82, 0.94],
                  snapAnimationDuration: const Duration(milliseconds: 220),
                  builder: (context, scrollController) {
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.responsive.radius(28)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: _PlayerSurface(
                          controller: widget.controller,
                          landscape: landscape,
                          artworkDirection: _artworkDirection,
                          onClose: widget.onClose,
                          onNext: _next,
                          onPrevious: _previous,
                          onOpenMore: _openMore,
                          scrollController: scrollController,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.controller,
    required this.landscape,
    required this.artworkDirection,
    required this.onClose,
    required this.onNext,
    required this.onPrevious,
    required this.onOpenMore,
    required this.scrollController,
  });

  final AudioLibraryController controller;
  final bool landscape;
  final int artworkDirection;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Future<void> Function(BuildContext, AudioTrack) onOpenMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final track = controller.currentTrack;
        final accent =
            controller.nowPlayingAccent ??
            Theme.of(context).colorScheme.primary;
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (track == null) {
          return ColoredBox(
            color: scheme.surface,
            child: Center(
              child: Text(
                'Choose a song to start listening.',
                style: TextStyle(fontSize: r.font(16)),
              ),
            ),
          );
        }

        final baseColor = isDark
            ? const Color(0xFF080B16)
            : const Color(0xFFFFF7FB);

        final backgroundColor = Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.22 : 0.12),
          baseColor,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: backgroundColor),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FutureBuilder<Uint8List?>(
                  future: controller.artworkFor(track),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;

                    if (bytes == null || bytes.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                      child: Transform.scale(
                        scale: 1.16,
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
              Positioned.fill(
                child: ColoredBox(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.46)
                      : Colors.white.withValues(alpha: 0.68),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark
                            ? Colors.black.withValues(alpha: 0.48)
                            : Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                        accent.withValues(alpha: isDark ? 0.10 : 0.06),
                        scheme.surface,
                      ],
                      stops: const [0.0, 0.30, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  _PlayerTopBar(
                    controller: controller,
                    onClose: onClose,
                    accent: accent,
                  ),
                  Expanded(
                    child: landscape
                        ? _LandscapeContent(
                            controller: controller,
                            artworkDirection: artworkDirection,
                            onNext: onNext,
                            onPrevious: onPrevious,
                            scrollController: scrollController,
                          )
                        : _PortraitContent(
                            controller: controller,
                            artworkDirection: artworkDirection,
                            onNext: onNext,
                            onPrevious: onPrevious,
                            scrollController: scrollController,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({
    required this.controller,
    required this.onClose,
    required this.accent,
  });

  final AudioLibraryController controller;
  final VoidCallback onClose;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(mobile: 8, tablet: 14, desktop: 20),
        vertical: r.value(mobile: 2, tablet: 4, desktop: 6),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close player',
            onPressed: onClose,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: r.icon(28)),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Now Playing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.font(15),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Equalizer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EqualizerPage(audioEngine: controller.audioEngine),
                ),
              );
            },
            icon: Icon(Icons.tune_rounded, size: r.icon(24), color: accent),
          ),
          IconButton(
            tooltip: 'Up Next',
            onPressed: () => _showUpNext(context, controller),
            icon: Icon(Icons.queue_music_rounded, size: r.icon(24)),
          ),
        ],
      ),
    );
  }
}

Future<void> _showUpNext(
  BuildContext context,
  AudioLibraryController controller,
) async {
  final currentTrack = controller.currentTrack;
  if (currentTrack == null) return;

  final currentIndex = controller.tracks.indexWhere(
    (track) => track.path == currentTrack.path,
  );

  final upcomingTracks = currentIndex >= 0
      ? controller.tracks.skip(currentIndex + 1).take(20).toList()
      : <AudioTrack>[];

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final r = sheetContext.responsive;
      final scheme = Theme.of(sheetContext).colorScheme;

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(r.radius(24)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                r.value(mobile: 18, tablet: 22, desktop: 26),
                r.value(mobile: 12, tablet: 14, desktop: 16),
                r.value(mobile: 10, tablet: 14, desktop: 18),
                r.value(mobile: 6, tablet: 8, desktop: 10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Up Next',
                      style: TextStyle(
                        fontSize: r.font(20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (upcomingTracks.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.value(mobile: 20, tablet: 24, desktop: 28),
                  18,
                  r.value(mobile: 20, tablet: 24, desktop: 28),
                  32,
                ),
                child: Text(
                  'No more songs in the queue',
                  style: TextStyle(fontSize: r.font(15)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    r.value(mobile: 10, tablet: 14, desktop: 18),
                    0,
                    r.value(mobile: 10, tablet: 14, desktop: 18),
                    16,
                  ),
                  itemCount: upcomingTracks.length,
                  itemBuilder: (context, index) {
                    final track = upcomingTracks[index];

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: r.scale(6),
                        vertical: r.scale(2),
                      ),
                      leading: TrackArtworkPreview(
                        title: track.name,
                        artwork: controller.artworkFor(track),
                        size: r.value(mobile: 52, tablet: 58, desktop: 64),
                      ),
                      title: Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.font(14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        track.artist.trim().isEmpty || track.artist == 'Unknown'
                            ? 'Local library'
                            : track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: r.font(12)),
                      ),
                      trailing: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: r.font(12),
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await controller.playTrack(
                          track,
                          source: controller.currentSource,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _PortraitContent extends StatelessWidget {
  const _PortraitContent({
    required this.controller,
    required this.artworkDirection,
    required this.onNext,
    required this.onPrevious,
    required this.scrollController,
  });

  final AudioLibraryController controller;
  final int artworkDirection;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final artSize =
            (constraints.maxWidth *
                    r.value(mobile: 0.82, tablet: 0.66, desktop: 0.58))
                .clamp(
                  r.value(mobile: 190, tablet: 240, desktop: 280),
                  r.value(mobile: 340, tablet: 440, desktop: 520),
                )
                .toDouble();

        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            r.value(mobile: 12, tablet: 22, desktop: 32),
            2,
            r.value(mobile: 12, tablet: 22, desktop: 32),
            r.value(mobile: 12, tablet: 18, desktop: 24),
          ),
          child: Column(
            children: [
              _SlidingArtwork(
                controller: controller,
                size: artSize,
                direction: artworkDirection,
              ),
              SizedBox(height: r.value(mobile: 12, tablet: 18, desktop: 22)),
              _TrackTitle(controller: controller),
              SizedBox(height: r.value(mobile: 7, tablet: 10, desktop: 14)),
              _ProgressSection(controller: controller),
              SizedBox(height: r.value(mobile: 6, tablet: 10, desktop: 14)),
              _MainControls(
                controller: controller,
                onNext: onNext,
                onPrevious: onPrevious,
              ),
              SizedBox(height: r.value(mobile: 16, tablet: 20, desktop: 24)),
              _ActionTray(
                controller: controller,
                track: controller.currentTrack!,
                onMore: () => _showMoreFromActionTray(context, controller),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LandscapeContent extends StatelessWidget {
  const _LandscapeContent({
    required this.controller,
    required this.artworkDirection,
    required this.onNext,
    required this.onPrevious,
    required this.scrollController,
  });

  final AudioLibraryController controller;
  final int artworkDirection;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = r.scale(8);
        final artSize =
            (constraints.maxHeight *
                    r.value(mobile: 0.70, tablet: 0.72, desktop: 0.74))
                .clamp(
                  r.value(mobile: 150, tablet: 180, desktop: 210),
                  r.value(mobile: 310, tablet: 360, desktop: 430),
                )
                .toDouble();

        return SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.45,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: _SlidingArtwork(
                        controller: controller,
                        size: artSize,
                        direction: artworkDirection,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 11,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      r.scale(4),
                      r.value(mobile: 8, tablet: 18, desktop: 26),
                      r.scale(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, controlConstraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: controlConstraints.maxWidth,
                            child: _LandscapeControls(
                              controller: controller,
                              onNext: onNext,
                              onPrevious: onPrevious,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LandscapeControls extends StatelessWidget {
  const _LandscapeControls({
    required this.controller,
    required this.onNext,
    required this.onPrevious,
  });

  final AudioLibraryController controller;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrackTitle(controller: controller),
        SizedBox(height: r.scale(6)),
        _ProgressSection(controller: controller),
        SizedBox(height: r.scale(5)),
        _MainControls(
          controller: controller,
          onNext: onNext,
          onPrevious: onPrevious,
        ),
        SizedBox(height: r.scale(10)),
        _ActionTray(
          controller: controller,
          track: controller.currentTrack!,
          onMore: () => _showMoreFromActionTray(context, controller),
        ),
      ],
    );
  }
}

Future<void> _showMoreFromActionTray(
  BuildContext context,
  AudioLibraryController controller,
) async {
  final track = controller.currentTrack;
  if (track == null) return;

  final action = await showModalBottomSheet<_MoreAction>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => const _MoreSheet(),
  );

  if (!context.mounted || action == null) return;

  if (action == _MoreAction.effects) {
    await _AudioEffectsSheet.show(context, controller: controller);
  } else if (action == _MoreAction.trackActions) {
    await TrackActions.show(context, controller: controller, track: track);
  }
}

class _ActionTray extends StatelessWidget {
  const _ActionTray({
    required this.controller,
    required this.track,
    required this.onMore,
  });

  final AudioLibraryController controller;
  final AudioTrack track;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final accent = controller.nowPlayingAccent ?? scheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(r.radius(24)),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ActionItem(
                icon: Icons.playlist_add_rounded,
                label: 'Add to Playlist',
                onPressed: () => TrackActions.showPlaylistPicker(
                  context,
                  controller: controller,
                  track: track,
                ),
              ),
            ),
            const _ActionDivider(),
            Expanded(
              child: _ActionItem(
                icon: Icons.share_rounded,
                label: 'Share',
                onPressed: () => controller.shareTrack(track),
              ),
            ),
            const _ActionDivider(),
            Expanded(
              child: _ActionItem(
                icon: Icons.mic_none_rounded,
                label: 'Karaoke',
                accent: accent,
                onPressed: () => controller.audioEngine.setKaraokeEnabled(
                  !controller.karaokeEnabled,
                ),
              ),
            ),
            const _ActionDivider(),
            Expanded(
              child: _ActionItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                onPressed: onMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(r.radius(22)),
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: r.scale(11),
          horizontal: r.scale(3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.icon(23), color: accent ?? scheme.onSurface),
            SizedBox(height: r.scale(4)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.82),
                fontSize: r.font(9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }
}

class _SlidingArtwork extends StatelessWidget {
  const _SlidingArtwork({
    required this.controller,
    required this.size,
    required this.direction,
  });

  final AudioLibraryController controller;
  final double size;
  final int direction;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.responsive.radius(20)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final begin = Offset(direction > 0 ? 1.0 : -1.0, 0);

          final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _ArtworkImage(
          key: ValueKey(track.path),
          controller: controller,
          track: track,
          size: size,
        ),
      ),
    );
  }
}

class _ArtworkImage extends StatefulWidget {
  const _ArtworkImage({
    super.key,
    required this.controller,
    required this.track,
    required this.size,
  });

  final AudioLibraryController controller;
  final AudioTrack track;
  final double size;

  @override
  State<_ArtworkImage> createState() => _ArtworkImageState();
}

class _ArtworkImageState extends State<_ArtworkImage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.controller.player.playingStream,
      initialData: widget.controller.player.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return AnimatedScale(
          scale: isPlaying ? 1.0 : 0.955,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  context.responsive.radius(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: isPlaying ? 0.20 : 0.10),
                    blurRadius: isPlaying ? 28 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  context.responsive.radius(20),
                ),
                child: FutureBuilder<Uint8List?>(
                  future: widget.controller.artworkFor(widget.track),
                  builder: (context, snapshot) {
                    return FullPlayerAlbumArt(
                      title: widget.track.name,
                      imageBytes: snapshot.data,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrackTitle extends StatelessWidget {
  const _TrackTitle({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final track = controller.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScrollingSongTitle(
                title: track.name,
                style: TextStyle(
                  fontSize: r.font(21),
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                track.artist.trim().isEmpty || track.artist == 'Unknown'
                    ? 'Local library'
                    : track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  fontSize: r.font(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _FavoriteButton(controller: controller, track: track),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.controller, required this.track});

  final AudioLibraryController controller;
  final AudioTrack track;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final favorite = controller.isFavorite(track);
    final accent = controller.nowPlayingAccent ?? scheme.primary;

    return IconButton(
      tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () => controller.toggleFavorite(track),
      icon: Icon(
        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: r.icon(28),
        color: favorite ? accent : scheme.onSurface,
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<bool>(
      stream: controller.player.playingStream,
      initialData: controller.player.playing,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;

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
                final accent = controller.nowPlayingAccent ?? scheme.primary;

                final waveTwo =
                    Color.lerp(accent, Colors.white, isDark ? 0.15 : 0.28) ??
                    accent;

                final waveThree =
                    Color.lerp(accent, Colors.black, isDark ? 0.10 : 0.06) ??
                    accent;

                return Column(
                  children: [
                    AnimatedWaveProgressBar(
                      position: position,
                      duration: duration,
                      isPlaying: isPlaying,
                      onSeek: controller.player.seek,
                      height: r.value(mobile: 46, tablet: 50, desktop: 54),
                      waveHeight: r.value(mobile: 7, tablet: 8, desktop: 9),
                      trackHeight: r.value(mobile: 8, tablet: 9, desktop: 9),
                      handleRadius: r.value(mobile: 7, tablet: 7.5, desktop: 8),
                      waveColor: accent,
                      waveHighlightColor: waveTwo,
                      trackColor: scheme.onSurface.withValues(
                        alpha: isDark ? 0.12 : 0.10,
                      ),
                      handleColor: waveThree,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: r.font(10),
                            color: scheme.onSurface.withValues(alpha: 0.60),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: r.font(10),
                            color: scheme.onSurface.withValues(alpha: 0.60),
                          ),
                        ),
                      ],
                    ),
                  ],
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

class _MainControls extends StatelessWidget {
  const _MainControls({
    required this.controller,
    required this.onNext,
    required this.onPrevious,
  });

  final AudioLibraryController controller;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final accent = controller.nowPlayingAccent ?? scheme.primary;

    return StreamBuilder<bool>(
      stream: controller.player.playingStream,
      initialData: controller.player.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Shuffle',
              onPressed: () =>
                  controller.toggleShuffle(!controller.shuffleEnabled),
              icon: Icon(
                Icons.shuffle_rounded,
                size: r.icon(25),
                color: controller.shuffleEnabled
                    ? accent
                    : scheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
            SizedBox(width: r.value(mobile: 8, tablet: 12, desktop: 16)),
            IconButton(
              tooltip: 'Previous song',
              onPressed: onPrevious,
              icon: Icon(Icons.skip_previous_rounded, size: r.icon(32)),
            ),
            SizedBox(width: r.value(mobile: 6, tablet: 10, desktop: 14)),
            Container(
              width: r.value(mobile: 64, tablet: 72, desktop: 78),
              height: r.value(mobile: 64, tablet: 72, desktop: 78),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: controller.togglePlayback,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    size: r.icon(34),
                    color: _contrast(accent),
                  ),
                ),
              ),
            ),
            SizedBox(width: r.value(mobile: 6, tablet: 10, desktop: 14)),
            IconButton(
              tooltip: 'Next song',
              onPressed: onNext,
              icon: Icon(Icons.skip_next_rounded, size: r.icon(32)),
            ),
            SizedBox(width: r.value(mobile: 8, tablet: 12, desktop: 16)),
            IconButton(
              tooltip: _repeatLabel(controller.repeatMode),
              onPressed: controller.cycleRepeatMode,
              icon: Icon(
                controller.repeatMode == AudioRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: r.icon(25),
                color: controller.repeatMode == AudioRepeatMode.off
                    ? scheme.onSurface.withValues(alpha: 0.70)
                    : accent,
              ),
            ),
          ],
        );
      },
    );
  }

  static Color _contrast(Color color) {
    return color.computeLuminance() > 0.48 ? Colors.black : Colors.white;
  }

  static String _repeatLabel(AudioRepeatMode mode) {
    return switch (mode) {
      AudioRepeatMode.off => 'Repeat off',
      AudioRepeatMode.all => 'Repeat all',
      AudioRepeatMode.one => 'Repeat current song',
    };
  }
}

enum _MoreAction { effects, trackActions }

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.radius(26))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            r.value(mobile: 18, tablet: 24, desktop: 30),
            14,
            r.value(mobile: 18, tablet: 24, desktop: 30),
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              SizedBox(height: r.scale(14)),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Speed, pitch, spatial & karaoke'),
                subtitle: const Text('Playback effects and equalizer'),
                onTap: () => Navigator.of(context).pop(_MoreAction.effects),
              ),
              ListTile(
                leading: const Icon(Icons.more_horiz_rounded),
                title: const Text('Track options'),
                subtitle: const Text(
                  'Share, playlist, remove, info and set as',
                ),
                onTap: () =>
                    Navigator.of(context).pop(_MoreAction.trackActions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _AudioEffectsSheet extends StatelessWidget {
  const _AudioEffectsSheet({required this.controller});

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
      builder: (_) => _AudioEffectsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListenableBuilder(
        listenable: controller.audioEngine,
        builder: (context, _) {
          final effects = controller.audioEngine.effects;
          final spatialEnabled = controller.spatialEnabled;
          final spatialDepth = controller.spatialDepth;
          final karaokeEnabled = controller.karaokeEnabled;

          return Material(
            color: scheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(r.radius(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                r.value(mobile: 18, tablet: 24, desktop: 30),
                12,
                r.value(mobile: 18, tablet: 24, desktop: 30),
                22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  SizedBox(height: r.scale(14)),
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
                  _EffectSlider(
                    title: 'Speed',
                    value: '${effects.speed.toStringAsFixed(2)}×',
                    slider: Slider(
                      value: effects.speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 30,
                      onChanged: controller.audioEngine.setSpeed,
                    ),
                  ),
                  _EffectSlider(
                    title: 'Pitch',
                    value:
                        '${effects.pitchSemitones >= 0 ? '+' : ''}'
                        '${effects.pitchSemitones.toStringAsFixed(1)} st',
                    slider: Slider(
                      value: effects.pitchSemitones,
                      min: -12,
                      max: 12,
                      divisions: 48,
                      onChanged: controller.audioEngine.setPitch,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.spatial_audio_rounded),
                    title: const Text('Spatial audio'),
                    subtitle: Text(
                      spatialEnabled
                          ? 'Depth ${(spatialDepth * 100).round()}%'
                          : 'Off',
                    ),
                    value: spatialEnabled,
                    onChanged: (enabled) {
                      controller.audioEngine.setSpatialEnabled(enabled);
                      controller.audioEngine.setSpatialDepth(spatialDepth);
                    },
                  ),
                  if (spatialEnabled)
                    Slider(
                      value: spatialDepth,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: controller.audioEngine.setSpatialDepth,
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.mic_off_rounded),
                    title: const Text('Karaoke'),
                    subtitle: Text(
                      karaokeEnabled
                          ? 'Vocal reduction on'
                          : 'Reduce centered vocals',
                    ),
                    value: karaokeEnabled,
                    onChanged: controller.audioEngine.setKaraokeEnabled,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EffectSlider extends StatelessWidget {
  const _EffectSlider({
    required this.title,
    required this.value,
    required this.slider,
  });

  final String title;
  final String value;
  final Widget slider;

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
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        slider,
      ],
    );
  }
}

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
      if (mounted) {
        setState(() {
          _needsScrolling = false;
        });
      }
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
        duration: Duration(milliseconds: 2200 + (maxScroll * 6).round()),
        curve: Curves.linear,
      );

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 900),
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
