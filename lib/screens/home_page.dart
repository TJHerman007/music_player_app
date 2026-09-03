import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_player_app/screens/search_page.dart';

import '../audio/audio_library.dart';
import '../utils/responsive.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';
import '../widgets/player_bar.dart';
import '../widgets/music_visual.dart';
import '../widgets/track_actions.dart';
import 'collection_page.dart';
import 'library_page.dart';
import 'settings_page.dart';

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
      if (mounted) {
        setState(() {});
      }

      if (mounted) {
        _scheduleGreetingRefresh();
      }
    });
  }

  Future<void> _restoreLibraryThenScanIfNeeded() async {
    // The cached library is restored first so opening the app never waits for
    // a device-wide music scan. New songs are discovered silently afterward.
    await widget.audioLibrary.ready;

    if (!mounted) return;

    unawaited(widget.audioLibrary.scanForNewSongsInBackground());
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
      if (mounted) {
        setState(() {});
      }

      if (mounted) {
        _scheduleGreetingRefresh();
      }
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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _OneMusicColors.background(context),

        // ---------------------------------------------------------------
        // EXISTING PLAYER BAR
        // ---------------------------------------------------------------
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

        // ---------------------------------------------------------------
        // EXISTING DYNAMIC ARTWORK BACKGROUND
        // ---------------------------------------------------------------
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: widget.audioLibrary,
                  builder: (context, _) {
                    final accent = widget.audioLibrary.nowPlayingAccent;

                    if (accent == null) {
                      return const SizedBox.shrink();
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.30),
                          radius: 1.15,
                          colors: [
                            accent.withValues(alpha: 0.46),
                            accent.withValues(alpha: 0.25),
                            accent.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.34, 0.68, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: widget.audioLibrary,
                  builder: (context, _) {
                    final accent = widget.audioLibrary.nowPlayingAccent;

                    if (accent == null) {
                      return const SizedBox.shrink();
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.30, 0.70, 1.0],
                          colors: [
                            accent.withValues(alpha: 0.18),
                            accent.withValues(alpha: 0.10),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            GlassBackground(
              accentListenable: widget.audioLibrary,
              accentProvider: () => widget.audioLibrary.nowPlayingAccent,
              child: RefreshIndicator(
                color: _OneMusicColors.accent(context),
                onRefresh: () async {
                  await widget.audioLibrary.scanDeviceMusic();
                },
                child: Padding(
                  // Same original responsive structure.
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    14,
                    r.horizontalPadding,
                    2,
                  ),
                  child: Column(
                    children: [
                      // =======================================================
                      // HEADER
                      // =======================================================

                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.value(
                              mobile: 4,
                              tablet: 8,
                              desktop: 10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Music',
                                style: TextStyle(
                                  color: _OneMusicColors.textPrimary(context),
                                  fontSize: r.font(30),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.15,
                                  height: 1,
                                ),
                              ),

                              const Spacer(),

                              _MinimalHeaderButton(
                                icon: Icons.search_rounded,
                                tooltip: 'Search',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SearchPage(
                                        audioLibrary: widget.audioLibrary,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(width: r.scale(8)),

                              _MinimalHeaderButton(
                                icon: Icons.settings_outlined,
                                tooltip: 'Settings',
                                onPressed: () => _openSettings(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: r.value(mobile: 28, tablet: 30, desktop: 32),
                      ),

                      // =======================================================
                      // NAVIGATION
                      // =======================================================
                      _CleanPillTabBar(),

                      SizedBox(
                        height: r.value(mobile: 28, tablet: 30, desktop: 32),
                      ),

                      // =======================================================
                      // CONTENT
                      // =======================================================
                      Expanded(
                        child: TabBarView(
                          children: [
                            _HomeSongsTab(
                              themeProvider: widget.themeProvider,
                              audioLibrary: widget.audioLibrary,
                            ),

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
// DESIGN COLORS
// ============================================================================

class _OneMusicColors {
  // Compatibility layer for the existing HomePage.
  //
  // The actual colors come from ThemeData, which is generated by AppTheme.
  // Keep these names so the rest of HomePage does not need to change.

  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.66);
  }

  static Color muted(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.42);
  }

  static Color accent(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color glass(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.055)
        : Colors.white.withValues(alpha: 0.48);
  }

  static Color glassStrong(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.085)
        : Colors.white.withValues(alpha: 0.68);
  }

  static Color glassBorder(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.black.withValues(alpha: 0.065);
  }
}

// ============================================================================
// MINIMAL HEADER BUTTON
// ============================================================================

class _MinimalHeaderButton extends StatelessWidget {
  const _MinimalHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: r.scale(23),
        padding: EdgeInsets.all(r.scale(7)),
        constraints: BoxConstraints(
          minWidth: r.value(mobile: 44, tablet: 46, desktop: 48),
          minHeight: r.value(mobile: 44, tablet: 46, desktop: 48),
        ),
        icon: Icon(
          icon,
          size: r.icon(25),
          color: _OneMusicColors.textPrimary(context),
        ),
      ),
    );
  }
}

class _CleanPillTabBar extends StatelessWidget {
  const _CleanPillTabBar();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final accent = _OneMusicColors.accent(context);

    return SizedBox(
      height: r.value(mobile: 52, tablet: 54, desktop: 56),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(
          horizontal: r.value(mobile: 2, tablet: 3, desktop: 4),
        ),
        indicator: BoxDecoration(
          color: Colors.white.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.055
                : 0.42,
          ),
          borderRadius: BorderRadius.circular(r.radius(26)),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.075
                  : 0.58,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        labelColor: accent,
        unselectedLabelColor: _OneMusicColors.textPrimary(context)
            .withValues(alpha: 0.66),
        labelStyle: TextStyle(
          fontSize: r.font(14),
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: r.font(14),
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          _TabPill(icon: Icons.auto_awesome_rounded, label: 'Discover'),
          _TabPill(icon: Icons.album_rounded, label: 'Albums'),
          _TabPill(icon: Icons.person_2_outlined, label: 'Artists'),
          _TabPill(icon: Icons.queue_music_rounded, label: 'Playlists'),
          _TabPill(icon: Icons.favorite_border_rounded, label: 'Liked'),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Tab(
      height: r.value(mobile: 44, tablet: 46, desktop: 48),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: r.value(mobile: 13, tablet: 15, desktop: 17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.icon(17)),
            SizedBox(width: r.scale(6)),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _HomeSongsTab extends StatelessWidget {
  const _HomeSongsTab({
    required this.themeProvider,
    required this.audioLibrary,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return ListenableBuilder(
      listenable: audioLibrary,
      builder: (context, child) {
        final tracks = audioLibrary.tracks;
        final recentlyPlayed = audioLibrary.recentlyPlayed;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.value(mobile: 0, tablet: 4, desktop: 8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // RECENTLY PLAYED
                    // =========================================================

                    if (recentlyPlayed.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Recently Played',
                            style: TextStyle(
                              color: _OneMusicColors.textPrimary(context),
                              fontSize: r.font(18),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.35,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _RecentlyPlayedPage(
                                    audioLibrary: audioLibrary,
                                  ),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.scale(2),
                                vertical: r.scale(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      color: _OneMusicColors.accent(context),
                                      fontSize: r.font(13),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: r.scale(4)),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: _OneMusicColors.accent(context),
                                    size: r.icon(18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r.scale(14)),

                      SizedBox(
                        height: r.value(mobile: 196, tablet: 214, desktop: 236),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: recentlyPlayed.length,
                          separatorBuilder: (_, _) => SizedBox(
                            width: r.value(mobile: 14, tablet: 16, desktop: 18),
                          ),
                          itemBuilder: (context, index) {
                            return _RecentlyPlayedCard(
                              track: recentlyPlayed[index],
                              controller: audioLibrary,
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        height: r.value(mobile: 28, tablet: 32, desktop: 36),
                      ),
                    ],

                    // =========================================================
                    // YOUR TRACKS
                    // =========================================================
                    if (tracks.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Your Tracks',
                            style: TextStyle(
                              color: _OneMusicColors.textPrimary(context),
                              fontSize: r.font(18),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.35,
                            ),
                          ),

                          const Spacer(),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                audioLibrary.toggleShuffle(
                                  !audioLibrary.shuffleEnabled,
                                );
                              },
                              borderRadius: BorderRadius.circular(r.radius(24)),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.value(
                                    mobile: 14,
                                    tablet: 16,
                                    desktop: 18,
                                  ),
                                  vertical: r.value(
                                    mobile: 9,
                                    tablet: 10,
                                    desktop: 11,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: audioLibrary.shuffleEnabled
                                      ? _OneMusicColors.accent(context)
                                            .withValues(alpha: 0.12)
                                      : _OneMusicColors.glass(context),
                                  borderRadius: BorderRadius.circular(
                                    r.radius(24),
                                  ),
                                  border: Border.all(
                                    color: audioLibrary.shuffleEnabled
                                        ? _OneMusicColors.accent(context)
                                              .withValues(alpha: 0.18)
                                        : _OneMusicColors.glassBorder(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shuffle_rounded,
                                      size: r.icon(17),
                                      color: _OneMusicColors.accent(context),
                                    ),
                                    SizedBox(width: r.scale(6)),
                                    Text(
                                      'Shuffle',
                                      style: TextStyle(
                                        color: _OneMusicColors.accent(context),
                                        fontSize: r.font(13),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: r.scale(12)),
                  ],
                ),
              ),
            ),

            if (tracks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: r.scale(12)),
                  child: Text(
                    'No songs found. Scan your phone to load your music.',
                    style: TextStyle(color: _OneMusicColors.secondary(context)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.value(mobile: 0, tablet: 4, desktop: 8),
                ),
                sliver: SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return _HomeTrackTile(
                      track: tracks[index],
                      controller: audioLibrary,
                    );
                  },
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: r.value(mobile: 28, tablet: 34, desktop: 40),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: _OneMusicColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Text(
              'See more',
              style: TextStyle(
                color: _OneMusicColors.accent(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RECENTLY PLAYED CARD
// ============================================================================

class _RecentlyPlayedCard extends StatelessWidget {
  const _RecentlyPlayedCard({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isSelected = controller.currentTrack?.path == track.path;
    final isPlaying = isSelected && controller.isPlaying;

    final cardWidth = r.value(mobile: 136, tablet: 154, desktop: 174);

    final artworkSize = cardWidth;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.playTrack(track, source: TrackSource.library);
          },
          onLongPress: () {
            TrackActions.show(context, controller: controller, track: track);
          },
          borderRadius: BorderRadius.circular(r.radius(17)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: artworkSize,
                height: artworkSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r.radius(17)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TrackArtworkPreview(
                        title: track.name,
                        artwork: controller.artworkFor(track),
                        size: artworkSize,
                      ),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.20),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: r.scale(7),
                        bottom: r.scale(7),
                        child: Container(
                          width: r.scale(34),
                          height: r.scale(34),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? _OneMusicColors.accent(context)
                                : Colors.white.withValues(alpha: 0.94),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: r.scale(10),
                                offset: Offset(0, r.scale(3)),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: isPlaying
                                ? Colors.white
                                : _OneMusicColors.accent(context),
                            size: r.icon(19),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: r.scale(9)),

              Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: r.font(13),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: -0.15,
                ),
              ),

              SizedBox(height: r.scale(3)),

              Text(
                track.artist.trim().isEmpty ? 'Unknown' : track.artist.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _OneMusicColors.secondary(context),
                  fontSize: r.font(11.5),
                  fontWeight: FontWeight.w500,
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
class _HomeTrackTile extends StatelessWidget {
  const _HomeTrackTile({required this.track, required this.controller});

  final AudioTrack track;
  final AudioLibraryController controller;

  Future<void> _showTrackMenu(BuildContext context) async {
    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox) return;

    final overlay = Overlay.of(context).context.findRenderObject();

    if (overlay is! RenderBox) return;

    final position = renderObject.localToGlobal(Offset.zero, ancestor: overlay);

    final size = renderObject.size;

    final screenSize = MediaQuery.sizeOf(context);

    final menuWidth = 230.0;
    const menuHeight = 190.0;

    double left = position.dx + size.width - menuWidth;

    if (left < 12) {
      left = 12;
    }

    if (left + menuWidth > screenSize.width - 12) {
      left = screenSize.width - menuWidth - 12;
    }

    double top = position.dy + size.height * 0.5;

    // Keep the popup on screen.
    if (top + menuHeight > screenSize.height - 20) {
      top = screenSize.height - menuHeight - 20;
    }

    if (top < 20) {
      top = 20;
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        screenSize.width - left - menuWidth,
        screenSize.height - top - menuHeight,
      ),
      color: _OneMusicColors.surface(context),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem<String>(
          value: 'playlist',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.playlist_add_rounded,
                size: 20,
                color: _OneMusicColors.textPrimary(context),
              ),
              const SizedBox(width: 12),
              Text(
                'Add to playlist',
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'favorite',
          height: 48,
          child: Row(
            children: [
              Icon(
                controller.isFavorite(track)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: controller.isFavorite(track)
                    ? _OneMusicColors.accent(context)
                    : _OneMusicColors.textPrimary(context),
              ),
              const SizedBox(width: 12),
              Text(
                controller.isFavorite(track)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'play',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: _OneMusicColors.textPrimary(context),
              ),
              const SizedBox(width: 12),
              Text(
                'Play now',
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'remove',
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                size: 20,
                color: _OneMusicColors.accent(context),
              ),
              const SizedBox(width: 12),
              Text(
                'Remove from library',
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || selected == null) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isSelected = controller.currentTrack?.path == track.path;
    final isPlaying = isSelected && controller.isPlaying;

    final artist = track.artist.trim().isEmpty
        ? 'Unknown'
        : track.artist.trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: r.value(mobile: 3, tablet: 5, desktop: 6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await controller.playTrack(track, source: TrackSource.library);
          },
          onLongPress: () {
            _showTrackMenu(context);
          },
          borderRadius: BorderRadius.circular(r.radius(20)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(mobile: 4, tablet: 6, desktop: 8),
              vertical: r.value(mobile: 7, tablet: 8, desktop: 9),
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? _OneMusicColors.accent(context).withValues(alpha: 0.020)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(r.radius(20)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.radius(12)),
                  child: TrackArtworkPreview(
                    title: track.name,
                    artwork: controller.artworkFor(track),
                    size: r.value(mobile: 52, tablet: 62, desktop: 68),
                  ),
                ),

                SizedBox(width: r.value(mobile: 13, tablet: 15, desktop: 17)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _OneMusicColors.textPrimary(context),
                          fontSize: r.font(14.5),
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: -0.18,
                          height: 1.15,
                        ),
                      ),

                      SizedBox(height: r.scale(4)),

                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _OneMusicColors.secondary(context),
                          fontSize: r.font(12),
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: r.scale(8)),

                if (isPlaying)
                  Padding(
                    padding: EdgeInsets.only(right: r.scale(10)),
                    child: NowPlayingIndicator(key: const ValueKey('playing')),
                  ),

                IconButton(
                  tooltip: 'More',
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                  splashRadius: r.scale(19),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: r.value(mobile: 34, tablet: 38, desktop: 40),
                    minHeight: r.value(mobile: 34, tablet: 38, desktop: 40),
                  ),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: r.icon(22),
                    color: _OneMusicColors.secondary(context),
                  ),
                  onPressed: () {
                    _showTrackMenu(context);
                  },
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
// RECENTLY PLAYED PAGE
// ============================================================================

class _RecentlyPlayedPage extends StatelessWidget {
  const _RecentlyPlayedPage({required this.audioLibrary});

  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OneMusicColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recently played'),
      ),
      bottomNavigationBar: PlayerBar(
        controller: audioLibrary,
        onOpenSource: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
      body: GlassBackground(
        accentListenable: audioLibrary,
        accentProvider: () => audioLibrary.nowPlayingAccent,
        child: ListenableBuilder(
          listenable: audioLibrary,
          builder: (context, child) {
            final recentlyPlayed = audioLibrary.recentlyPlayed;

            if (recentlyPlayed.isEmpty) {
              return Center(
                child: Text(
                  'No recently played songs yet.',
                  style: TextStyle(color: _OneMusicColors.secondary(context)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              itemCount: recentlyPlayed.length,
              itemBuilder: (context, index) {
                return _HomeTrackTile(
                  track: recentlyPlayed[index],
                  controller: audioLibrary,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH PAGE
// ============================================================================

class _SearchPage extends StatefulWidget {
  const _SearchPage({required this.audioLibrary});

  final AudioLibraryController audioLibrary;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final TextEditingController _controller = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OneMusicColors.background(context),
      body: GlassBackground(
        accentListenable: widget.audioLibrary,
        accentProvider: () => widget.audioLibrary.nowPlayingAccent,
        child: SafeArea(
          child: Column(
            children: [
              // ===========================================================
              // SEARCH HEADER
              // ===========================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 18, 14),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      splashRadius: 22,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 19,
                        color: _OneMusicColors.textPrimary(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: _OneMusicColors.surface(context)
                              .withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          style: TextStyle(
                            color: _OneMusicColors.textPrimary(context),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search songs...',
                            hintStyle: TextStyle(
                              color: _OneMusicColors.muted(context),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 21,
                              color: _OneMusicColors.secondary(context),
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                      color: _OneMusicColors.secondary(context),
                                    ),
                                    onPressed: () {
                                      _controller.clear();

                                      setState(() {
                                        _query = '';
                                      });
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===========================================================
              // RESULTS
              // ===========================================================
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.audioLibrary,
                  builder: (context, child) {
                    final query = _query.trim().toLowerCase();

                    if (query.isEmpty) {
                      return const _SearchEmptyState(
                        icon: Icons.search_rounded,
                        title: 'Search your music',
                        subtitle: 'Find songs in your local library',
                      );
                    }

                    final results = widget.audioLibrary.tracks
                        .where(
                          (track) => track.name.toLowerCase().contains(query),
                        )
                        .toList();

                    if (results.isEmpty) {
                      return const _SearchEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No songs found',
                        subtitle: 'Try another search',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 30),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        return _HomeTrackTile(
                          track: results[index],
                          controller: widget.audioLibrary,
                        );
                      },
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
// SEARCH EMPTY STATE
// ============================================================================

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _OneMusicColors.muted(context)),

            const SizedBox(height: 14),

            Text(
              title,
              style: TextStyle(
                color: _OneMusicColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _OneMusicColors.secondary(context),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
