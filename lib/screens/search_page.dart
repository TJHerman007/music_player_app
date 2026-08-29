import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../widgets/glass_surface.dart';
import '../widgets/music_visual.dart';
import '../widgets/track_actions.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({required this.audioLibrary, super.key});

  final AudioLibraryController audioLibrary;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AudioTrack> _results(List<AudioTrack> tracks) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final words = query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final results = tracks.where((track) {
      final name = track.name.toLowerCase();
      return words.every(name.contains);
    }).toList();

    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aStarts = aName.startsWith(query);
      final bStarts = bName.startsWith(query);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      final aContains = aName.contains(query);
      final bContains = bName.contains(query);
      if (aContains != bContains) return aContains ? -1 : 1;
      return aName.compareTo(bName);
    });

    return results;
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.audioLibrary.nowPlayingAccent ??
        _SearchColors.accent(context);

    return Scaffold(
      backgroundColor: _SearchColors.background(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.45),
                    radius: 1.25,
                    colors: [
                      accent.withValues(alpha: 0.32),
                      accent.withValues(alpha: 0.16),
                      accent.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.35, 0.68, 1],
                  ),
                ),
              ),
            ),
          ),
          GlassBackground(
            accentListenable: widget.audioLibrary,
            accentProvider: () => widget.audioLibrary.nowPlayingAccent,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 20, 10),
                    child: Row(
                      children: [
                        _BackButton(onPressed: () => Navigator.of(context).pop()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SearchField(
                            controller: _controller,
                            focusNode: _focusNode,
                            query: _query,
                            accent: accent,
                            onChanged: (value) => setState(() => _query = value),
                            onClear: _clear,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: widget.audioLibrary,
                      builder: (context, child) {
                        final tracks = widget.audioLibrary.tracks;
                        final results = _results(tracks);

                        if (_query.trim().isEmpty) {
                          return _SearchIdleState(
                            accent: accent,
                            trackCount: tracks.length,
                          );
                        }

                        if (results.isEmpty) {
                          return _SearchNoResults(
                            query: _query,
                            accent: accent,
                            onClear: _clear,
                          );
                        }

                        return _SearchResults(
                          results: results,
                          controller: widget.audioLibrary,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.accent,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final Color accent;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 52,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: query.isNotEmpty
              ? accent.withValues(alpha: 0.30)
              : scheme.onSurface.withValues(alpha: 0.075),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        cursorColor: accent,
        style: TextStyle(
          color: _SearchColors.textPrimary(context),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Search your music',
          hintStyle: TextStyle(
            color: _SearchColors.muted(context),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: query.isNotEmpty
                ? accent
                : _SearchColors.secondary(context),
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  splashRadius: 20,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: _SearchColors.secondary(context),
                  ),
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _SearchColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.controller});

  final List<AudioTrack> results;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final accent = controller.nowPlayingAccent ??
        _SearchColors.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
          child: Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: TextStyle(
              color: _SearchColors.secondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 3),
            itemBuilder: (context, index) {
              return _SearchTrackTile(
                track: results[index],
                controller: controller,
                accent: accent,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchTrackTile extends StatelessWidget {
  const _SearchTrackTile({
    required this.track,
    required this.controller,
    required this.accent,
  });

  final AudioTrack track;
  final AudioLibraryController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final selected = controller.currentTrack?.path == track.path;
    final playing = selected && controller.isPlaying;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.playTrack(
          track,
          source: TrackSource.library,
        ),
        onLongPress: () => TrackActions.show(
          context,
          controller: controller,
          track: track,
        ),
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: TrackArtworkPreview(
                  title: track.name,
                  artwork: controller.artworkFor(track),
                  size: 58,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _SearchColors.textPrimary(context),
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playing
                          ? 'Playing now'
                          : selected
                              ? 'Paused'
                              : 'Local library',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: playing
                            ? accent
                            : _SearchColors.secondary(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: controller.isFavorite(track)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                splashRadius: 21,
                icon: Icon(
                  controller.isFavorite(track)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: controller.isFavorite(track)
                      ? accent
                      : _SearchColors.muted(context),
                ),
                onPressed: () => controller.toggleFavorite(track),
              ),
              SizedBox(
                width: 34,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: playing
                      ? const NowPlayingIndicator(key: ValueKey('playing'))
                      : Icon(
                          Icons.play_circle_outline_rounded,
                          key: const ValueKey('play'),
                          size: 23,
                          color: accent,
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

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState({required this.accent, required this.trackCount});

  final Color accent;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.search_rounded, size: 30, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              'Search your music',
              style: TextStyle(
                color: _SearchColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trackCount == 0
                  ? 'Your music library is empty'
                  : 'Find any song in your $trackCount-song library',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SearchColors.secondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults({
    required this.query,
    required this.accent,
    required this.onClear,
  });

  final String query;
  final Color accent;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
              ),
              child: Icon(Icons.search_off_rounded, size: 30, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              'No songs found',
              style: TextStyle(
                color: _SearchColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing matched “$query”',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SearchColors.secondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchColors {
  static const Color darkBackground = Color(0xFF101010);
  static const Color lightBackground = Color(0xFFF4F2EE);
  static const Color darkText = Color(0xFFF1EFEB);
  static const Color lightText = Color(0xFF181817);
  static const Color darkSecondary = Color(0xFF9B9995);
  static const Color lightSecondary = Color(0xFF77746F);
  static const Color darkMuted = Color(0xFF6F6D69);
  static const Color lightMuted = Color(0xFF99958F);
  static const Color darkAccent = Color(0xFFE46F50);
  static const Color lightAccent = Color(0xFFD85E40);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkText
          : lightText;

  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSecondary
          : lightSecondary;

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkMuted
          : lightMuted;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkAccent
          : lightAccent;
}
