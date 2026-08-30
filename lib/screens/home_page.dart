import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_player_app/screens/search_page.dart';

import '../audio/audio_library.dart';
import '../utils/responsive.dart';
import '../theme/theme_provider.dart';
import '../widgets/player_bar.dart';
import '../widgets/music_visual.dart';
import '../widgets/track_actions.dart';
import 'collection_page.dart';
import 'library_page.dart';
import 'settings_page.dart';

/// Home shell redesigned from scratch.
///
/// IMPORTANT:
/// - Existing audio/library/navigation logic is intentionally preserved.
/// - This file does not use GlassBackground or GlassSurface.
/// - Visual styling is completely independent from the previous UI.
class HomePage extends StatefulWidget {
  const HomePage({
    required this.themeProvider,
    required this.audioLibrary,
    super.key,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _restoreLibraryThenScanIfNeeded();

    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    _greetingTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleGreetingRefresh();
    });
  }

  Future<void> _restoreLibraryThenScanIfNeeded() async {
    await widget.audioLibrary.ready;

    if (!mounted || widget.audioLibrary.tracks.isNotEmpty) {
      return;
    }

    await widget.audioLibrary.scanDeviceMusic();
  }

  void _scheduleGreetingRefresh() {
    _greetingTimer?.cancel();

    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    _greetingTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleGreetingRefresh();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _StudioColors.background(context),
        bottomNavigationBar: ListenableBuilder(
          listenable: widget.audioLibrary,
          builder: (context, child) {
            return PlayerBar(
              controller: widget.audioLibrary,
              onOpenSource: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LibraryPage(
                    themeProvider: widget.themeProvider,
                    audioLibrary: widget.audioLibrary,
                  ),
                ),
              ),
            );
          },
        ),
        body: Stack(
          children: [
            // A restrained ambient glow replaces the old glass/background system.
            Positioned(
              top: -170,
              right: -150,
              child: ListenableBuilder(
                listenable: widget.audioLibrary,
                builder: (context, _) {
                  final accent = widget.audioLibrary.nowPlayingAccent;
                  if (accent == null) return const SizedBox.shrink();

                  return IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.12),
                            accent.withValues(alpha: 0.035),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.horizontalPadding,
                      r.value(mobile: 10, tablet: 14, desktop: 18),
                      r.horizontalPadding,
                      0,
                    ),
                    child: _StudioHeader(
                      onSearch: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SearchPage(audioLibrary: widget.audioLibrary),
                          ),
                        );
                      },
                      onSettings: () => _openSettings(context),
                    ),
                  ),

                  SizedBox(
                    height: r.value(mobile: 24, tablet: 28, desktop: 34),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.horizontalPadding,
                    ),
                    child: const _StudioTabs(),
                  ),

                  SizedBox(
                    height: r.value(mobile: 18, tablet: 22, desktop: 26),
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _StudioDiscoverTab(audioLibrary: widget.audioLibrary),
                        CollectionPage(
                          title: 'Albums',
                          icon: Icons.album_rounded,
                          audioLibrary: widget.audioLibrary,
                        ),
                        CollectionPage(
                          title: 'Artists',
                          icon: Icons.person_2_rounded,
                          audioLibrary: widget.audioLibrary,
                        ),
                        CollectionPage(
                          title: 'Playlists',
                          icon: Icons.queue_music_rounded,
                          audioLibrary: widget.audioLibrary,
                        ),
                        CollectionPage(
                          title: 'Liked songs',
                          icon: Icons.favorite_rounded,
                          audioLibrary: widget.audioLibrary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeProvider: widget.themeProvider,
          audioLibrary: widget.audioLibrary,
        ),
      ),
    );
  }
}

// ============================================================================
// STUDIO THEME
// ============================================================================

class _StudioColors {
  static Color background(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF0B0714)
        : const Color(0xFFF9EFF7);
  }

  static Color panel(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF151020)
        : const Color(0xFFFFF8FC);
  }

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

// ============================================================================
// HEADER
// ============================================================================

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.onSearch, required this.onSettings});

  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Music',
              style: TextStyle(
                color: _StudioColors.text(context),
                fontSize: r.value(mobile: 30, tablet: 32, desktop: 34),
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        const Spacer(),
        _HeaderIconButton(icon: Icons.search_rounded, onPressed: onSearch),
        SizedBox(width: r.scale(5)),
        _HeaderIconButton(icon: Icons.settings_outlined, onPressed: onSettings),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 18) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return IconButton(
      onPressed: onPressed,
      splashRadius: r.scale(22),
      icon: Icon(icon, size: r.icon(24), color: _StudioColors.text(context)),
    );
  }
}

// ============================================================================
// TAB NAVIGATION
// ============================================================================

class _StudioTabs extends StatelessWidget {
  const _StudioTabs();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final accent = _StudioColors.accent(context);

    return SizedBox(
      height: r.value(mobile: 58, tablet: 60, desktop: 62),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: 0.16), width: 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
        labelColor: accent,
        unselectedLabelColor: _StudioColors.secondary(context),
        labelPadding: EdgeInsets.symmetric(
          horizontal: r.value(mobile: 17, tablet: 20, desktop: 22),
        ),
        labelStyle: TextStyle(
          fontSize: r.font(13.5),
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: r.font(13.5),
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          _PillTab('Discover'),
          _PillTab('Albums'),
          _PillTab('Artists'),
          _PillTab('Playlists'),
          _PillTab('Liked'),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(child: Text(label));
  }
}

// ============================================================================
// DISCOVER
// ============================================================================

class _StudioDiscoverTab extends StatelessWidget {
  const _StudioDiscoverTab({required this.audioLibrary});

  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return RefreshIndicator(
      color: _StudioColors.accent(context),
      onRefresh: audioLibrary.scanDeviceMusic,
      child: ListenableBuilder(
        listenable: audioLibrary,
        builder: (context, _) {
          final tracks = audioLibrary.tracks;
          final recent = audioLibrary.recentlyPlayed;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  r.horizontalPadding,
                  0,
                  r.horizontalPadding,
                  110,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (recent.isNotEmpty) ...[
                      _SectionTitle(
                        title: 'Recently Played',
                        action: 'See all',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _RecentlyPlayedPage(
                                audioLibrary: audioLibrary,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: r.scale(12)),
                      SizedBox(
                        height: r.value(mobile: 188, tablet: 216, desktop: 238),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: recent.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: r.scale(16)),
                          itemBuilder: (context, index) {
                            return _RecentArtworkCard(
                              track: recent[index],
                              controller: audioLibrary,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: r.scale(30)),
                    ],

                    Row(
                      children: [
                        Text(
                          'All songs',
                          style: TextStyle(
                            color: _StudioColors.text(context),
                            fontSize: r.font(20),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        _ShuffleButton(controller: audioLibrary),
                      ],
                    ),
                    SizedBox(height: r.scale(12)),
                  ]),
                ),
              ),

              if (tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMusicState(onScan: audioLibrary.scanDeviceMusic),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.horizontalPadding,
                  ),
                  sliver: SliverList.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      return _StudioTrackTile(
                        track: tracks[index],
                        controller: audioLibrary,
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: _StudioColors.text(context),
            fontSize: r.font(19),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                action,
                style: TextStyle(
                  color: _StudioColors.accent(context),
                  fontSize: r.font(12.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_rounded,
                size: r.icon(16),
                color: _StudioColors.accent(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RECENT CARD
// ============================================================================

class _RecentArtworkCard extends StatelessWidget {
  const _RecentArtworkCard({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final width = r.value(mobile: 136, tablet: 150, desktop: 166);
    final selected = controller.currentTrack?.path == track.path;
    final playing = selected && controller.isPlaying;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _StudioColors.accent(context).withValues(alpha: 0.10),
          highlightColor: _StudioColors.accent(context).withValues(alpha: 0.04),
          onTap: () async {
            if (controller.currentTrack?.path == track.path) {
              await controller.togglePlayback();
            } else {
              await controller.playTrack(track, source: TrackSource.library);
            }
          },
          onLongPress: () =>
              TrackActions.show(context, controller: controller, track: track),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: TrackArtworkPreview(
                          title: track.name,
                          artwork: controller.artworkFor(track),
                          size: width,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface
                                .withValues(alpha: 0.94),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: _StudioColors.accent(context),
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  track.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _StudioColors.text(context),
                    fontSize: r.font(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  track.artist.trim().isEmpty ? 'Unknown artist' : track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _StudioColors.secondary(context),
                    fontSize: r.font(11.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHUFFLE
// ============================================================================

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({required this.controller});

  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final accent = _StudioColors.accent(context);
    final enabled = controller.shuffleEnabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => controller.toggleShuffle(!enabled),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.value(mobile: 14, tablet: 16, desktop: 18),
            vertical: r.value(mobile: 9, tablet: 10, desktop: 11),
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: enabled ? 0.11 : 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.18 : 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shuffle_rounded, size: r.icon(17), color: accent),
              const SizedBox(width: 6),
              Text(
                enabled ? 'Shuffle on' : 'Shuffle',
                style: TextStyle(
                  color: accent,
                  fontSize: r.font(12.5),
                  fontWeight: FontWeight.w800,
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
// TRACK ROW
// ============================================================================

class _StudioTrackTile extends StatelessWidget {
  const _StudioTrackTile({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  Future<void> _showTrackMenu(BuildContext context) async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;

    final position = renderObject.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderObject.size;
    final screen = MediaQuery.sizeOf(context);

    const menuWidth = 230.0;
    const menuHeight = 190.0;

    var left = position.dx + size.width - menuWidth;
    left = left.clamp(12.0, screen.width - menuWidth - 12.0);

    var top = position.dy + size.height * 0.5;
    if (top + menuHeight > screen.height - 20) {
      top = screen.height - menuHeight - 20;
    }
    if (top < 20) top = 20;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        screen.width - left - menuWidth,
        screen.height - top - menuHeight,
      ),
      color: _StudioColors.panel(context),
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _menuItem(
          value: 'playlist',
          icon: Icons.playlist_add_rounded,
          label: 'Add to playlist',
          context: context,
        ),
        _menuItem(
          value: 'favorite',
          icon: controller.isFavorite(track)
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: controller.isFavorite(track)
              ? 'Remove from favorites'
              : 'Add to favorites',
          context: context,
        ),
        _menuItem(
          value: 'play',
          icon: Icons.play_arrow_rounded,
          label: 'Play now',
          context: context,
        ),
        _menuItem(
          value: 'remove',
          icon: Icons.remove_circle_outline_rounded,
          label: 'Remove from library',
          context: context,
        ),
      ],
    );

    if (!context.mounted || selected == null) return;

    switch (selected) {
      case 'playlist':
        await TrackActions.showPlaylistPicker(
          context,
          controller: controller,
          track: track,
        );
        break;
      case 'favorite':
        controller.toggleFavorite(track);
        break;
      case 'play':
        await controller.playTrack(track, source: TrackSource.library);
        break;
      case 'remove':
        controller.removeTrack(track);
        break;
    }
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: _StudioColors.text(context)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: _StudioColors.text(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final selected = controller.currentTrack?.path == track.path;
    final playing = selected && controller.isPlaying;

    final artist = track.artist.trim().isEmpty
        ? 'Unknown artist'
        : track.artist.trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: r.value(mobile: 3, tablet: 5, desktop: 6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _StudioColors.accent(context).withValues(alpha: 0.10),
          highlightColor: _StudioColors.accent(context).withValues(alpha: 0.04),
          onTap: () async {
            if (controller.currentTrack?.path == track.path) {
              await controller.togglePlayback();
            } else {
              await controller.playTrack(track, source: TrackSource.library);
            }
          },
          onLongPress: () => _showTrackMenu(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: r.value(mobile: 7, tablet: 9, desktop: 10),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: -2,
                      height: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _StudioColors.accent(context)
                                  .withValues(alpha: 0.16),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: TrackArtworkPreview(
                        title: track.name,
                        artwork: controller.artworkFor(track),
                        size: r.value(mobile: 54, tablet: 60, desktop: 64),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: r.scale(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? _StudioColors.accent(context)
                              : _StudioColors.text(context),
                          fontSize: r.font(14.2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _StudioColors.secondary(context),
                          fontSize: r.font(11.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (playing)
                  Padding(
                    padding: EdgeInsets.only(right: r.scale(12)),
                    child: _AnimatedEqualizer(
                      key: const ValueKey('playing'),
                      color: _StudioColors.accent(context),
                    ),
                  ),
                IconButton(
                  tooltip: 'More',
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                  splashRadius: r.scale(18),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: r.icon(21),
                    color: _StudioColors.secondary(context),
                  ),
                  onPressed: () => _showTrackMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ACTUAL ANIMATED EQUALIZER
// ============================================================================

class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer({super.key, required this.color});

  final Color color;

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final heights = <double>[
            7 + 9 * t,
            14 - 6 * t,
            9 + 10 * t,
            16 - 8 * t,
          ];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < heights.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 2.0),
                  child: Container(
                    width: 3,
                    height: heights[i],
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyMusicState extends StatelessWidget {
  const _EmptyMusicState({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    final accent = _StudioColors.accent(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 42,
              color: _StudioColors.muted(context),
            ),
            const SizedBox(height: 14),
            Text(
              'Your library is empty',
              style: TextStyle(
                color: _StudioColors.text(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan your device to find your music.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _StudioColors.secondary(context),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onScan,
              icon: Icon(Icons.refresh_rounded, color: accent),
              label: Text(
                'Scan music',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RECENTLY PLAYED PAGE
// ============================================================================

class _RecentlyPlayedPage extends StatelessWidget {
  const _RecentlyPlayedPage({required this.audioLibrary});

  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: _StudioColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recently played',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: PlayerBar(
        controller: audioLibrary,
        onOpenSource: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
      body: ListenableBuilder(
        listenable: audioLibrary,
        builder: (context, _) {
          final recent = audioLibrary.recentlyPlayed;

          if (recent.isEmpty) {
            return Center(
              child: Text(
                'No recently played songs yet.',
                style: TextStyle(color: _StudioColors.secondary(context)),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              12,
              r.horizontalPadding,
              30,
            ),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              return _StudioTrackTile(
                track: recent[index],
                controller: audioLibrary,
              );
            },
          );
        },
      ),
    );
  }
}
