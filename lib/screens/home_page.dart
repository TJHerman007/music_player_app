import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
                  child: Column(
                    children: [
                      // =======================================================
                      // HEADER
                      // =======================================================

                      SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            Text(
                              '1ne Music',
                              style: TextStyle(
                                color: _OneMusicColors.textPrimary(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),

                            const Spacer(),

                            _MinimalHeaderButton(
                              icon: Icons.search_rounded,
                              tooltip: 'Search',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _SearchPage(
                                      audioLibrary: widget.audioLibrary,
                                    ),
                                  ),
                                );
                              },
                            ),

                            _MinimalHeaderButton(
                              icon: Icons.tune_rounded,
                              tooltip: 'Settings',
                              onPressed: () => _openSettings(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =======================================================
                      // NAVIGATION
                      // =======================================================
                      const _CleanPillTabBar(),

                      const SizedBox(height: 16),

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
                              title: 'Playlists',
                              icon: Icons.queue_music_rounded,
                              audioLibrary: widget.audioLibrary,
                            ),

                            CollectionPage(
                              title: 'Artists',
                              icon: Icons.person_2_rounded,
                              audioLibrary: widget.audioLibrary,
                            ),

                            CollectionPage(
                              title: 'Albums',
                              icon: Icons.album_rounded,
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
  static const Color darkBackground = Color(0xFF101010);

  static const Color darkSurface = Color(0xFF171717);

  static const Color darkSurfaceLight = Color(0xFF202020);

  static const Color darkText = Color(0xFFF1EFEB);

  static const Color darkSecondary = Color(0xFF9B9995);

  static const Color darkMuted = Color(0xFF6F6D69);

  static const Color darkAccent = Color(0xFFE46F50);

  static const Color lightBackground = Color(0xFFF4F2EE);

  static const Color lightSurface = Color(0xFFECE9E4);

  static const Color lightText = Color(0xFF181817);

  static const Color lightSecondary = Color(0xFF77746F);

  static const Color lightAccent = Color(0xFFD85E40);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondary
        : lightSecondary;
  }

  static Color muted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkMuted
        : lightSecondary;
  }

  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : lightAccent;
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      icon: Icon(icon, size: 21, color: _OneMusicColors.textPrimary(context)),
    );
  }
}

// ============================================================================
// TOP NAVIGATION
// ============================================================================

class _CleanPillTabBar extends StatelessWidget {
  const _CleanPillTabBar();

  @override
  Widget build(BuildContext context) {
    final accent = _OneMusicColors.accent(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,

          labelPadding: const EdgeInsets.symmetric(horizontal: 3),

          indicatorSize: TabBarIndicatorSize.tab,

          indicator: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(18),
          ),

          labelColor: Colors.white,

          unselectedLabelColor: _OneMusicColors.secondary(context),

          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),

          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),

          tabs: const [
            _TabPill(icon: Icons.music_note_rounded, label: 'All Songs'),
            _TabPill(icon: Icons.playlist_play_rounded, label: 'Playlists'),
            _TabPill(icon: Icons.person_2_rounded, label: 'Artists'),
            _TabPill(icon: Icons.album_rounded, label: 'Albums'),
            _TabPill(icon: Icons.favorite_rounded, label: 'Liked'),
          ],
        ),
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
    return Tab(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME TAB
// ============================================================================

class _HomeSongsTab extends StatelessWidget {
  const _HomeSongsTab({
    required this.themeProvider,
    required this.audioLibrary,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return ListenableBuilder(
      listenable: audioLibrary,
      builder: (context, child) {
        final tracks = audioLibrary.tracks;

        final recentlyPlayed = audioLibrary.recentlyPlayed;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          slivers: [
            // =============================================================
            // TOP CONTENT
            // =============================================================

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),

                  // -------------------------------------------------------
                  // GREETING
                  // -------------------------------------------------------
                  Text(
                    greeting,
                    style: TextStyle(
                      color: _OneMusicColors.textPrimary(context),
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    tracks.isEmpty
                        ? 'Your music library is empty'
                        : '${tracks.length} songs in your library',
                    style: TextStyle(
                      color: _OneMusicColors.secondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // -------------------------------------------------------
                  // RECENTLY PLAYED
                  // -------------------------------------------------------
                  if (recentlyPlayed.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    _SectionHeader(
                      title: 'Recently played',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _RecentlyPlayedPage(audioLibrary: audioLibrary),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 174,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: recentlyPlayed.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 15),
                        itemBuilder: (context, index) {
                          return _RecentlyPlayedCard(
                            track: recentlyPlayed[index],
                            controller: audioLibrary,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 27),
                  ],

                  // -------------------------------------------------------
                  // ALL SONGS
                  // -------------------------------------------------------
                  if (tracks.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          'All songs',
                          style: TextStyle(
                            color: _OneMusicColors.textPrimary(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${tracks.length}',
                          style: TextStyle(
                            color: _OneMusicColors.muted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 9),
                ],
              ),
            ),

            // =============================================================
            // EMPTY STATE
            // =============================================================
            if (tracks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No songs found. Scan your phone to load your music.',
                    style: TextStyle(color: _OneMusicColors.secondary(context)),
                  ),
                ),
              )
            // =============================================================
            // SONG LIST
            // =============================================================
            else
              SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  return _HomeTrackTile(
                    track: tracks[index],
                    controller: audioLibrary,
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    final isSelected = controller.currentTrack?.path == track.path;

    final isPlaying = isSelected && controller.isPlaying;

    return SizedBox(
      width: 128,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.playTrack(track, source: TrackSource.library);
          },
          onLongPress: () {
            TrackActions.show(context, controller: controller, track: track);
          },
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------
              // ARTWORK
              // -----------------------------------------------------------

              SizedBox(
                width: 128,
                height: 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TrackArtworkPreview(
                        title: track.name,
                        artwork: controller.artworkFor(track),
                        size: 128,
                      ),

                      // Very subtle bottom gradient.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Play button.
                      Positioned(
                        right: 7,
                        bottom: 7,
                        child: Container(
                          width: 33,
                          height: 33,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // -----------------------------------------------------------
              // TITLE
              // -----------------------------------------------------------
              Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _OneMusicColors.textPrimary(context),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.currentTrack?.path == track.path;

    final isPlaying = isSelected && controller.isPlaying;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await controller.playTrack(track, source: TrackSource.library);
          },
          onLongPress: () {
            TrackActions.show(context, controller: controller, track: track);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                // ---------------------------------------------------------
                // ARTWORK
                // ---------------------------------------------------------

                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: TrackArtworkPreview(
                    title: track.name,
                    artwork: controller.artworkFor(track),
                    size: 56,
                  ),
                ),

                const SizedBox(width: 14),

                // ---------------------------------------------------------
                // TITLE
                // ---------------------------------------------------------
                Expanded(
                  child: Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _OneMusicColors.textPrimary(context),
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: -0.15,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ---------------------------------------------------------
                // FAVORITE
                // ---------------------------------------------------------
                IconButton(
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                  splashRadius: 20,
                  tooltip: controller.isFavorite(track)
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  icon: Icon(
                    controller.isFavorite(track)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 19,
                    color: controller.isFavorite(track)
                        ? _OneMusicColors.accent(context)
                        : _OneMusicColors.muted(context),
                  ),
                  onPressed: () {
                    controller.toggleFavorite(track);
                  },
                ),

                const SizedBox(width: 6),

                // ---------------------------------------------------------
                // PLAYING INDICATOR
                // ---------------------------------------------------------
                SizedBox(
                  width: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isPlaying
                        ? const NowPlayingIndicator(key: ValueKey('playing'))
                        : Icon(
                            Icons.play_circle_outline_rounded,
                            key: const ValueKey('play'),
                            size: 22,
                            color: _OneMusicColors.accent(context),
                          ),
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
