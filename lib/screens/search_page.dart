import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../widgets/glass_surface.dart';
import '../widgets/music_visual.dart';
import '../widgets/player_bar.dart';
import '../widgets/track_actions.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({required this.audioLibrary, super.key});

  final AudioLibraryController audioLibrary;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _recentSearches = [
    'shape of you',
    'blinding lights',
    'after hours',
    'in the end',
    'perfect',
  ];

  String _query = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  List<AudioTrack> _getResults() {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final words = query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final results = widget.audioLibrary.tracks.where((track) {
      final name = track.name.toLowerCase();

      return words.every(name.contains);
    }).toList();

    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      final aStarts = aName.startsWith(query);
      final bStarts = bName.startsWith(query);

      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }

      return aName.compareTo(bName);
    });

    return results;
  }

  void _performSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == query.toLowerCase(),
      );

      _recentSearches.insert(0, query);

      if (_recentSearches.length > 8) {
        _recentSearches.removeLast();
      }

      _query = query;
      _selectedTab = 0;
    });

    _searchFocusNode.unfocus();
  }

  void _selectRecentSearch(String value) {
    _searchController.text = value;

    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );

    _performSearch(value);
  }

  void _removeRecentSearch(String value) {
    setState(() {
      _recentSearches.remove(value);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _query = '';
      _selectedTab = 0;
    });

    _searchFocusNode.requestFocus();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1018),

      // Keep the existing mini-player.
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.audioLibrary,
        builder: (context, _) {
          return PlayerBar(
            controller: widget.audioLibrary,
            onOpenSource: () {},
          );
        },
      ),

      body: ListenableBuilder(
        listenable: widget.audioLibrary,
        builder: (context, _) {
          final accent =
              widget.audioLibrary.nowPlayingAccent ?? const Color(0xFFFF7462);

          return _SearchBackground(
            accent: accent,
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _ResponsiveSearchLayout(
                    width: constraints.maxWidth,
                    audioLibrary: widget.audioLibrary,
                    accent: accent,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    query: _query,
                    selectedTab: _selectedTab,
                    recentSearches: _recentSearches,

                    // IMPORTANT:
                    // _getResults() belongs to _SearchPageState.
                    // We calculate it here and pass the result down.
                    results: _getResults(),

                    onQueryChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },

                    onSearchSubmitted: _performSearch,

                    onClearSearch: _clearSearch,

                    onBack: () {
                      Navigator.of(context).pop();
                    },

                    onRecentSearch: _selectRecentSearch,

                    onRemoveRecent: _removeRecentSearch,

                    onClearAllRecent: _clearAllRecentSearches,

                    onTabChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// RESPONSIVE SEARCH LAYOUT
// ============================================================================

class _ResponsiveSearchLayout extends StatelessWidget {
  const _ResponsiveSearchLayout({
    required this.width,
    required this.audioLibrary,
    required this.accent,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.selectedTab,
    required this.recentSearches,
    required this.results,
    required this.onQueryChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onBack,
    required this.onRecentSearch,
    required this.onRemoveRecent,
    required this.onClearAllRecent,
    required this.onTabChanged,
  });

  final double width;

  final AudioLibraryController audioLibrary;
  final Color accent;

  final TextEditingController controller;
  final FocusNode focusNode;

  final String query;
  final int selectedTab;

  final List<String> recentSearches;

  // Search results are supplied by _SearchPageState.
  final List<AudioTrack> results;

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;

  final VoidCallback onBack;

  final ValueChanged<String> onRecentSearch;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearAllRecent;

  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    // =========================================================================
    // RESPONSIVE VALUES
    // =========================================================================

    final double horizontalPadding = isPhone
        ? 24
        : isTablet
        ? 38
        : 46;

    final double maxContentWidth = isPhone
        ? double.infinity
        : isTablet
        ? 720
        : 850;

    final double titleSize = isPhone
        ? 31
        : isTablet
        ? 34
        : 38;

    final double searchHeight = isPhone ? 76 : 82;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // =================================================================
              // HEADER
              // =================================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: isPhone ? 8 : 18),
                  child: Row(
                    children: [
                      _ReferenceBackButton(
                        onPressed: onBack,
                        size: isPhone ? 58 : 62,
                      ),

                      SizedBox(width: isPhone ? 22 : 25),

                      Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================================
              // SEARCH BAR
              // =================================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: isPhone ? 20 : 25),
                  child: _ReferenceSearchBar(
                    controller: controller,
                    focusNode: focusNode,
                    query: query,
                    accent: accent,
                    height: searchHeight,
                    onChanged: onQueryChanged,
                    onSubmitted: onSearchSubmitted,
                    onClear: onClearSearch,
                  ),
                ),
              ),

              // =================================================================
              // IDLE STATE
              // =================================================================
              if (query.trim().isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: isPhone ? 27 : 34),
                    child: _RecentSearches(
                      searches: recentSearches,
                      accent: accent,
                      onTap: onRecentSearch,
                      onRemove: onRemoveRecent,
                      onClearAll: onClearAllRecent,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isPhone ? 40 : 54,
                      bottom: 32,
                    ),
                    child: _DiscoveryArea(
                      audioLibrary: audioLibrary,
                      accent: accent,
                      isPhone: isPhone,
                    ),
                  ),
                ),
              ]
              // =================================================================
              // RESULTS
              // =================================================================
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: isPhone ? 22 : 28),
                    child: _SearchTabs(
                      selected: selectedTab,
                      accent: accent,
                      isPhone: isPhone,
                      onChanged: onTabChanged,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: isPhone ? 25 : 30),
                    child: Row(
                      children: [
                        Text(
                          '${results.length} Results',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: isPhone ? 16 : 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        Icon(
                          Icons.tune_rounded,
                          color: Colors.white.withValues(alpha: 0.82),
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          'Most Relevant',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: isPhone ? 15 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================================
                // RESULTS LIST
                // =================================================================
                if (results.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoResultsState(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: isPhone ? 18 : 22,
                      bottom: 30,
                    ),
                    sliver: SliverList.separated(
                      itemCount: results.length,

                      separatorBuilder: (_, _) => const SizedBox(height: 10),

                      itemBuilder: (context, index) {
                        return _SearchResultTile(
                          track: results[index],
                          controller: audioLibrary,
                          accent: accent,
                          isPhone: isPhone,
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACK BUTTON
// ============================================================================

class _ReferenceBackButton extends StatelessWidget {
  const _ReferenceBackButton({required this.onPressed, required this.size});

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.035),
            border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: size * 0.49,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH BAR
// ============================================================================

class _ReferenceSearchBar extends StatelessWidget {
  const _ReferenceSearchBar({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.accent,
    required this.height,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final String query;
  final Color accent;
  final double height;

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: Colors.black.withValues(alpha: 0.20),
        border: Border.all(color: accent.withValues(alpha: 0.68), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: accent,
        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: 'Search your music',

          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.64),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 31,
          ),

          prefixIconConstraints: BoxConstraints(
            minWidth: 64,
            minHeight: height,
          ),

          suffixIcon: query.trim().isEmpty
              ? const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 29,
                )
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),

          suffixIconConstraints: BoxConstraints(
            minWidth: 62,
            minHeight: height,
          ),

          contentPadding: const EdgeInsets.symmetric(vertical: 24),
        ),
      ),
    );
  }
}

// ============================================================================
// RECENT SEARCHES
// ============================================================================

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.accent,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> searches;
  final Color accent;

  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            GestureDetector(
              onTap: onClearAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        if (searches.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No recent searches',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 15,
              ),
            ),
          )
        else
          Column(
            children: searches.map((search) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentSearchRow(
                  text: search,
                  accent: accent,
                  onTap: () => onTap(search),
                  onRemove: () => onRemove(search),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ============================================================================
// RECENT SEARCH ROW
// ============================================================================

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.text,
    required this.accent,
    required this.onTap,
    required this.onRemove,
  });

  final String text;
  final Color accent;

  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
          ),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: accent, size: 29),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              IconButton(
                onPressed: onRemove,
                splashRadius: 21,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 27,
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
// SEARCH TABS
// ============================================================================

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({
    required this.selected,
    required this.accent,
    required this.isPhone,
    required this.onChanged,
  });

  final int selected;
  final Color accent;
  final bool isPhone;
  final ValueChanged<int> onChanged;

  static const labels = ['Songs', 'Artists', 'Albums', 'Playlists'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final selectedNow = selected == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 9),
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isPhone ? 50 : 54,
                decoration: BoxDecoration(
                  color: selectedNow ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 16 : 17,
                    fontWeight: selectedNow ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// SEARCH RESULT TILE
// ============================================================================

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.track,
    required this.controller,
    required this.accent,
    required this.isPhone,
  });

  final AudioTrack track;
  final AudioLibraryController controller;
  final Color accent;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final selected = controller.currentTrack?.path == track.path;

    final playing = selected && controller.isPlaying;

    final artworkSize = isPhone ? 82.0 : 88.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (playing) {
            await controller.pauseTrack();
          } else {
            await controller.playTrack(track, source: TrackSource.library);
          }
        },

        onLongPress: () {
          TrackActions.show(context, controller: controller, track: track);
        },

        borderRadius: BorderRadius.circular(20),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: isPhone ? 106 : 114,
          padding: const EdgeInsets.all(11),

          decoration: BoxDecoration(
            color: playing
                ? accent.withValues(alpha: 0.13)
                : Colors.white.withValues(alpha: 0.025),

            borderRadius: BorderRadius.circular(20),

            border: Border.all(
              color: playing
                  ? accent.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.13),
            ),
          ),

          child: Row(
            children: [
              // ===============================================================
              // ARTWORK
              // ===============================================================

              ClipRRect(
                borderRadius: BorderRadius.circular(13),

                child: TrackArtworkPreview(
                  title: track.name,
                  artwork: controller.artworkFor(track),
                  size: artworkSize,
                ),
              ),

              const SizedBox(width: 16),

              // ===============================================================
              // TEXT
              // ===============================================================
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: playing ? accent : Colors.white,

                        fontSize: isPhone ? 18 : 19,

                        fontWeight: FontWeight.w600,

                        letterSpacing: -0.25,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      playing ? 'Playing now' : 'Local library',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withValues(alpha: 0.56),

                        fontSize: isPhone ? 14 : 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // ===============================================================
              // FAVORITE
              // ===============================================================
              IconButton(
                tooltip: controller.isFavorite(track)
                    ? 'Remove from favorites'
                    : 'Add to favorites',

                splashRadius: 21,

                onPressed: () {
                  controller.toggleFavorite(track);
                },

                icon: Icon(
                  controller.isFavorite(track)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,

                  color: controller.isFavorite(track)
                      ? accent
                      : Colors.white.withValues(alpha: 0.82),

                  size: 25,
                ),
              ),

              const SizedBox(width: 3),

              // ===============================================================
              // PLAY / PAUSE
              // ===============================================================
              SizedBox(
                width: isPhone ? 54 : 58,
                height: isPhone ? 54 : 58,

                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),

                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },

                  child: playing
                      ? Container(
                          key: const ValueKey('pause'),

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),

                          child: Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: isPhone ? 28 : 30,
                          ),
                        )
                      : Container(
                          key: const ValueKey('play'),

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                          ),

                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: isPhone ? 28 : 30,
                          ),
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
// DISCOVERY AREA
// ============================================================================

class _DiscoveryArea extends StatelessWidget {
  const _DiscoveryArea({
    required this.audioLibrary,
    required this.accent,
    required this.isPhone,
  });

  final AudioLibraryController audioLibrary;
  final Color accent;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final favorites = audioLibrary.tracks.where(audioLibrary.isFavorite).length;

    return Column(
      children: [
        const _SearchIllustration(),

        const SizedBox(height: 22),

        const Text(
          'Search your music',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Find songs, artists, albums\nor playlists from your library',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: isPhone ? 17 : 18,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: _DiscoveryCard(
                icon: Icons.favorite_rounded,
                title: 'Favorites',
                value: '$favorites songs',
                accent: accent,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _DiscoveryCard(
                icon: Icons.music_note_rounded,
                title: 'Top Played',
                value: '${audioLibrary.tracks.length} songs',
                accent: accent,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _DiscoveryCard(
                icon: Icons.history_rounded,
                title: 'Recently Added',
                value: '${audioLibrary.tracks.length} songs',
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// DISCOVERY CARD
// ============================================================================

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, color: accent, size: 35),

          const SizedBox(height: 14),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH ILLUSTRATION
// ============================================================================

class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,

      child: CustomPaint(painter: _SearchIllustrationPainter()),
    );
  }
}

class _SearchIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.40, size.height * 0.40);

    final glowPaint = Paint()
      ..color = const Color(0xFFFF6F5C).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);

    canvas.drawCircle(center, 42, glowPaint);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFFFF7662);

    canvas.drawCircle(center, 42, circlePaint);

    final handle = Path()
      ..moveTo(center.dx + 30, center.dy + 31)
      ..lineTo(center.dx + 66, center.dy + 67);

    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFF8B73),
    );

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.28);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.83),
        width: 125,
        height: 15,
      ),
      shadowPaint,
    );

    final sparklePaint = Paint()
      ..color = const Color(0xFFFF7662)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    void sparkle(double x, double y, double length) {
      canvas.drawLine(
        Offset(x, y - length),
        Offset(x, y + length),
        sparklePaint,
      );

      canvas.drawLine(
        Offset(x - length, y),
        Offset(x + length, y),
        sparklePaint,
      );
    }

    sparkle(size.width * 0.13, size.height * 0.30, 3.5);

    sparkle(size.width * 0.86, size.height * 0.22, 3);

    sparkle(size.width * 0.74, size.height * 0.78, 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// NO RESULTS
// ============================================================================

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFFFF7462),
            size: 54,
          ),

          const SizedBox(height: 16),

          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Try searching for another song',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BACKGROUND
// ============================================================================

class _SearchBackground extends StatelessWidget {
  const _SearchBackground({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,

      children: [
        Container(color: const Color(0xFF0B1018)),

        // =====================================================================
        // MAIN ACCENT GLOW
        // =====================================================================
        Positioned(
          top: -170,
          right: -100,

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 700),

            width: 560,
            height: 560,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.62),

                  accent.withValues(alpha: 0.28),

                  accent.withValues(alpha: 0.08),

                  Colors.transparent,
                ],

                stops: const [0.0, 0.38, 0.68, 1.0],
              ),
            ),
          ),
        ),

        // =====================================================================
        // DARK LOWER AREA
        // =====================================================================
        Positioned(
          left: -160,
          bottom: -250,

          child: Container(
            width: 560,
            height: 600,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: RadialGradient(
                colors: [
                  const Color(0xFF172131).withValues(alpha: 0.55),

                  const Color(0xFF0B1018).withValues(alpha: 0.70),

                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // =====================================================================
        // RIGHT ACCENT WASH
        // =====================================================================
        Positioned(
          top: 120,
          right: -180,
          bottom: 100,

          child: Container(
            width: 430,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,

                colors: [
                  accent.withValues(alpha: 0.18),

                  accent.withValues(alpha: 0.08),

                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
