import 'package:flutter/material.dart';

import 'dart:typed_data';

class MusicVisual extends StatelessWidget {
  const MusicVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: _Tile(
              color: const Color(0xFFEF6F61),
              icon: Icons.graphic_eq_rounded,
              size: 118,
            ),
          ),
          Transform.translate(
            offset: const Offset(78, 18),
            child: Transform.rotate(
              angle: 0.15,
              child: _Tile(
                color: const Color(0xFF56B4A8),
                icon: Icons.headphones_rounded,
                size: 92,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(-68, 28),
            child: Transform.rotate(
              angle: 0.18,
              child: _Tile(
                color: colors.primary,
                icon: Icons.music_note_rounded,
                size: 78,
              ),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF24202F),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.album_rounded,
              size: 58,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class ThreeDAlbumArt extends StatelessWidget {
  const ThreeDAlbumArt({
    required this.title,
    this.imageBytes,
    this.size = 148,
    super.key,
  });

  final String title;
  final Uint8List? imageBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = [
      const Color(0xFFFF8FAB),
      const Color(0xFFFFB86B),
      const Color(0xFF75D6C5),
      const Color(0xFF9C8CFF),
    ][title.hashCode.abs() % 4];
    return SizedBox(
      width: size + 18,
      height: size + 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(7, 9),
            child: Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.06,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, Color.lerp(accent, Colors.white, 0.32)!],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: size * 0.18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_rounded,
                                size: size * 0.36,
                                color: Colors.white,
                              ),
                              Icon(
                                Icons.sentiment_satisfied_alt_rounded,
                                size: size * 0.28,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ],
                          )
                        : Image.memory(
                            imageBytes!,
                            width: size * 0.62,
                            height: size * 0.62,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: size * 0.15,
                      color: Colors.white.withValues(alpha: 0.82),
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

class TrackArtworkPreview extends StatelessWidget {
  const TrackArtworkPreview({
    required this.title,
    required this.artwork,
    this.size = 48,
    super.key,
  });

  final String title;
  final Future<Uint8List?> artwork;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = [
      const Color(0xFFEF6F61),
      const Color(0xFF56B4A8),
      const Color(0xFF7668D8),
      const Color(0xFFFFA54B),
    ][title.hashCode.abs() % 4];

    return FutureBuilder<Uint8List?>(
      future: artwork,
      builder: (context, snapshot) {
        final imageBytes = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size,
            height: size,
            child: imageBytes == null
                ? ColoredBox(
                    color: accent,
                    child: const Icon(Icons.album_rounded, color: Colors.white),
                  )
                : Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.low,
                  ),
          ),
        );
      },
    );
  }
}

class FullPlayerAlbumArt extends StatelessWidget {
  const FullPlayerAlbumArt({required this.title, this.imageBytes, super.key});

  final String title;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final accent = [
      const Color(0xFFFF8FAB),
      const Color(0xFFFFB86B),
      const Color(0xFF75D6C5),
      const Color(0xFF9C8CFF),
    ][title.hashCode.abs() % 4];
    return AspectRatio(
      aspectRatio: 0.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: imageBytes == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, Colors.black87]),
                ),
                child: const Center(
                  child: Icon(
                    Icons.album_rounded,
                    size: 88,
                    color: Colors.white,
                  ),
                ),
              )
            : Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
  }
}

class NowPlayingIndicator extends StatefulWidget {
  const NowPlayingIndicator({super.key});

  @override
  State<NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.82,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeInOut)),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.icon, required this.size});

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.42, color: Colors.white),
    );
  }
}
