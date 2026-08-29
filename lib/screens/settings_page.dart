import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';
import 'library_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeProvider,
    required this.audioLibrary,
    super.key,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        accentListenable: audioLibrary,
        accentProvider: () => audioLibrary.nowPlayingAccent,
        child: ListenableBuilder(
          listenable: Listenable.merge([audioLibrary, themeProvider]),
          builder: (context, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            final accent = audioLibrary.nowPlayingAccent;

            return Stack(
              children: [
                // ==========================================================
                // CURRENT SONG COLOR GRADIENT
                // ==========================================================

                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        gradient: accent == null
                            ? null
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.25, 0.55, 1.0],
                                colors: [
                                  accent.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  ),
                                  accent.withValues(
                                    alpha: isDark ? 0.10 : 0.055,
                                  ),
                                  accent.withValues(
                                    alpha: isDark ? 0.035 : 0.02,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                // ==========================================================
                // SETTINGS CONTENT
                // ==========================================================
                _EdgeSwipeBack(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      // ====================================================
                      // CUSTOM HEADER
                      // ====================================================

                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 28),
                          child: SizedBox(
                            height: 48,
                            child: Center(
                              child: Text(
                                'Settings',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ====================================================
                      // APPEARANCE
                      // ====================================================
                      const _SettingsSectionTitle(title: 'Appearance'),

                      const SizedBox(height: 16),

                      const _SettingsHeaderRow(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        subtitle: 'Choose how the app follows appearance',
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {themeProvider.themeMode},
                          onSelectionChanged: (selection) {
                            themeProvider.setThemeMode(selection.first);
                          },
                        ),
                      ),

                      const SizedBox(height: 22),

                      _SettingsNavigationTile(
                        icon: Icons.folder_open_rounded,
                        title: 'Add tracks',
                        subtitle: 'Choose music files from your device',
                        onTap: () => _addTracks(context),
                      ),

                      const _SettingsDivider(),

                      _SettingsNavigationTile(
                        icon: Icons.image_outlined,
                        title: 'Home artwork',
                        subtitle: 'Choose an image from your device',
                        onTap: () => _changeHomeImage(context),
                      ),

                      const SizedBox(height: 38),

                      // ====================================================
                      // PLAYBACK
                      // ====================================================
                      const _SettingsSectionTitle(title: 'Playback'),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        secondary: const Icon(Icons.shuffle_rounded),
                        title: const Text(
                          'Shuffle',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Play songs in a random order'),
                        value: audioLibrary.shuffleEnabled,
                        onChanged: audioLibrary.toggleShuffle,
                      ),

                      const SizedBox(height: 12),

                      const _SettingsHeaderRow(
                        icon: Icons.repeat_rounded,
                        title: 'Repeat',
                        subtitle: 'Choose off, all songs, or one song',
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SegmentedButton<AudioRepeatMode>(
                          segments: const [
                            ButtonSegment(
                              value: AudioRepeatMode.off,
                              icon: Icon(Icons.repeat_rounded),
                              label: Text('Off'),
                            ),
                            ButtonSegment(
                              value: AudioRepeatMode.all,
                              icon: Icon(Icons.repeat_rounded),
                              label: Text('All'),
                            ),
                            ButtonSegment(
                              value: AudioRepeatMode.one,
                              icon: Icon(Icons.repeat_one_rounded),
                              label: Text('One'),
                            ),
                          ],
                          selected: {audioLibrary.repeatMode},
                          onSelectionChanged: (selection) {
                            audioLibrary.setRepeatMode(selection.first);
                          },
                        ),
                      ),

                      const SizedBox(height: 38),

                      // ====================================================
                      // EXCLUDE FROM LIBRARY
                      // ====================================================
                      const _SettingsSectionTitle(
                        title: 'Exclude from library',
                      ),

                      const SizedBox(height: 16),

                      _ExclusionSwitch(
                        extension: 'mp3',
                        controller: audioLibrary,
                      ),

                      const _SettingsDivider(),

                      _ExclusionSwitch(
                        extension: 'wav',
                        controller: audioLibrary,
                      ),

                      const _SettingsDivider(),

                      _ExclusionSwitch(
                        extension: 'flac',
                        controller: audioLibrary,
                      ),

                      const _SettingsDivider(),

                      _ExclusionSwitch(
                        extension: 'm4a',
                        controller: audioLibrary,
                      ),

                      const _SettingsDivider(),

                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        secondary: const Icon(Icons.visibility_off_outlined),
                        title: const Text(
                          'Hidden files',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Hide files in dot folders'),
                        value: audioLibrary.excludeHiddenFiles,
                        onChanged: audioLibrary.setExcludeHiddenFiles,
                      ),

                      const SizedBox(height: 38),

                      // ====================================================
                      // MANAGE
                      // ====================================================
                      const _SettingsSectionTitle(title: 'Manage'),

                      const SizedBox(height: 16),

                      _SettingsNavigationTile(
                        icon: Icons.library_music_outlined,
                        title:
                            '${audioLibrary.tracks.length} tracks in library',
                        subtitle: 'Add, remove, and manage your music',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LibraryPage(
                              themeProvider: themeProvider,
                              audioLibrary: audioLibrary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ==========================================================
                // PINNED BACK BUTTON
                // ==========================================================
                Positioned(
                  top: 20,
                  left: 15,
                  child: SafeArea(
                    bottom: false,
                    child: _PinnedBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                      accent: accent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // ADD TRACKS
  // ==========================================================

  Future<void> _addTracks(BuildContext context) async {
    final added = await audioLibrary.importAudioFiles();

    if (!context.mounted) return;

    final message =
        audioLibrary.errorMessage ??
        (added ? 'Tracks added to your library.' : 'No tracks selected.');

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // CHANGE HOME ARTWORK
  // ==========================================================

  Future<void> _changeHomeImage(BuildContext context) async {
    final changed = await audioLibrary.pickHomeImage();

    if (!context.mounted) return;

    final message =
        audioLibrary.errorMessage ??
        (changed ? 'Home artwork updated.' : 'No image was selected.');

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ==========================================================
// PINNED BACK BUTTON
// ==========================================================

class _PinnedBackButton extends StatelessWidget {
  const _PinnedBackButton({required this.onPressed, this.accent});

  final VoidCallback onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                accent?.withValues(alpha: isDark ? 0.16 : 0.10) ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.045)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.16),
              width: 0.7,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.82),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// EDGE SWIPE BACK
// ==========================================================

class _EdgeSwipeBack extends StatefulWidget {
  const _EdgeSwipeBack({required this.child});

  final Widget child;

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  double _startX = 0;
  double _currentX = 0;
  bool _tracking = false;

  void _onPointerDown(PointerDownEvent event) {
    // Only begin when the gesture starts
    // very close to the left screen edge.
    if (event.position.dx <= 28) {
      _startX = event.position.dx;
      _currentX = _startX;
      _tracking = true;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_tracking) return;

    _currentX = event.position.dx;

    if (_currentX - _startX > 100) {
      _tracking = false;

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _tracking = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _tracking = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}

// ==========================================================
// SECTION TITLE
// ==========================================================

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.15),
      ),
    );
  }
}

// ==========================================================
// HEADER ROW
// ==========================================================

class _SettingsHeaderRow extends StatelessWidget {
  const _SettingsHeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color
        ?.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// NAVIGATION TILE
// ==========================================================

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color
        ?.withValues(alpha: 0.68);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 23),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, size: 22, color: mutedColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// DIVIDER
// ==========================================================

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 43),
      child: Divider(
        height: 1,
        thickness: 0.6,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
      ),
    );
  }
}

// ==========================================================
// EXCLUSION SWITCH
// ==========================================================

class _ExclusionSwitch extends StatelessWidget {
  const _ExclusionSwitch({required this.extension, required this.controller});

  final String extension;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final excluded = controller.excludedExtensions.contains(extension);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      secondary: const Icon(Icons.audio_file_outlined),
      title: Text(
        '.$extension files',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      value: excluded,
      onChanged: (value) {
        controller.setExtensionExcluded(extension, value);
      },
    );
  }
}

// import 'package:flutter/material.dart';

// import '../audio/audio_library.dart';
// import '../theme/theme_provider.dart';
// import '../widgets/glass_surface.dart';
// import 'library_page.dart';

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({
//     required this.themeProvider,
//     required this.audioLibrary,
//     super.key,
//   });

//   final ThemeProvider themeProvider;
//   final AudioLibraryController audioLibrary;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: GlassBackground(
//         accentListenable: audioLibrary,
//         accentProvider: () => audioLibrary.nowPlayingAccent,
//         child: ListenableBuilder(
//           listenable: Listenable.merge([
//             audioLibrary,
//             themeProvider,
//           ]),
//           builder: (context, child) {
//             final theme = Theme.of(context);
//             final isDark =
//                 theme.brightness == Brightness.dark;

//             final accent =
//                 audioLibrary.nowPlayingAccent ??
//                     theme.colorScheme.primary;

//             final size = MediaQuery.sizeOf(context);

//             final horizontalPadding =
//                 _responsiveValue(
//               size.width,
//               mobile: 20,
//               tablet: 38,
//               desktop: 60,
//             );

//             return Stack(
//               children: [
//                 // ==========================================================
//                 // CURRENT SONG COLOR
//                 // Same visual language as the new player/homepage.
//                 // ==========================================================

//                 Positioned.fill(
//                   child: IgnorePointer(
//                     child: AnimatedContainer(
//                       duration:
//                           const Duration(milliseconds: 900),
//                       curve: Curves.easeInOutCubic,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           stops: const [
//                             0.0,
//                             0.20,
//                             0.48,
//                             0.78,
//                             1.0,
//                           ],
//                           colors: [
//                             accent.withValues(
//                               alpha:
//                                   isDark ? 0.20 : 0.10,
//                             ),
//                             accent.withValues(
//                               alpha:
//                                   isDark ? 0.13 : 0.065,
//                             ),
//                             accent.withValues(
//                               alpha:
//                                   isDark ? 0.055 : 0.025,
//                             ),
//                             Colors.transparent,
//                             Colors.transparent,
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // ==========================================================
//                 // CONTENT
//                 // ==========================================================

//                 _EdgeSwipeBack(
//                   child: CustomScrollView(
//                     physics:
//                         const BouncingScrollPhysics(),
//                     slivers: [
//                       // ====================================================
//                       // HEADER
//                       // ====================================================

//                       SliverPadding(
//                         padding: EdgeInsets.fromLTRB(
//                           horizontalPadding,
//                           8,
//                           horizontalPadding,
//                           0,
//                         ),
//                         sliver: SliverToBoxAdapter(
//                           child: SafeArea(
//                             bottom: false,
//                             child: Padding(
//                               padding:
//                                   const EdgeInsets.only(
//                                 bottom: 30,
//                               ),
//                               child: _SettingsHeader(
//                                 accent: accent,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),

//                       // ====================================================
//                       // SETTINGS
//                       // ====================================================

//                       SliverPadding(
//                         padding: EdgeInsets.fromLTRB(
//                           horizontalPadding,
//                           0,
//                           horizontalPadding,
//                           40,
//                         ),
//                         sliver: SliverToBoxAdapter(
//                           child: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                             children: [
//                               // ==================================================
//                               // APPEARANCE
//                               // ==================================================

//                               const _SectionTitle(
//                                 title: 'Appearance',
//                               ),

//                               const SizedBox(
//                                 height: 18,
//                               ),

//                               _SettingInfoRow(
//                                 icon:
//                                     Icons.palette_outlined,
//                                 title: 'Theme',
//                                 subtitle:
//                                     'Choose how the app follows appearance',
//                                 accent: accent,
//                               ),

//                               const SizedBox(
//                                 height: 14,
//                               ),

//                               _AccentSegmentedButton<
//                                   ThemeMode>(
//                                 accent: accent,
//                                 segments: const [
//                                   ButtonSegment(
//                                     value:
//                                         ThemeMode.light,
//                                     icon: Icon(
//                                       Icons
//                                           .light_mode_outlined,
//                                     ),
//                                     label:
//                                         Text('Light'),
//                                   ),
//                                   ButtonSegment(
//                                     value:
//                                         ThemeMode.system,
//                                     icon: Icon(
//                                       Icons
//                                           .brightness_auto_outlined,
//                                     ),
//                                     label:
//                                         Text('System'),
//                                   ),
//                                   ButtonSegment(
//                                     value:
//                                         ThemeMode.dark,
//                                     icon: Icon(
//                                       Icons
//                                           .dark_mode_outlined,
//                                     ),
//                                     label:
//                                         Text('Dark'),
//                                   ),
//                                 ],
//                                 selected: {
//                                   themeProvider.themeMode,
//                                 },
//                                 onSelectionChanged:
//                                     (selection) {
//                                   themeProvider
//                                       .setThemeMode(
//                                     selection.first,
//                                   );
//                                 },
//                               ),

//                               const SizedBox(
//                                 height: 38,
//                               ),

//                               // ==================================================
//                               // PLAYBACK
//                               // ==================================================

//                               const _SectionTitle(
//                                 title: 'Playback',
//                               ),

//                               const SizedBox(
//                                 height: 16,
//                               ),

//                               _SwitchSettingRow(
//                                 icon:
//                                     Icons.shuffle_rounded,
//                                 title: 'Shuffle',
//                                 subtitle:
//                                     'Play songs in a random order',
//                                 value:
//                                     audioLibrary
//                                         .shuffleEnabled,
//                                 accent: accent,
//                                 onChanged:
//                                     audioLibrary
//                                         .toggleShuffle,
//                               ),

//                               const SizedBox(
//                                 height: 12,
//                               ),

//                               _SettingInfoRow(
//                                 icon:
//                                     Icons.repeat_rounded,
//                                 title: 'Repeat',
//                                 subtitle:
//                                     'Choose off, all songs, or one song',
//                                 accent: accent,
//                               ),

//                               const SizedBox(
//                                 height: 14,
//                               ),

//                               _AccentSegmentedButton<
//                                   AudioRepeatMode>(
//                                 accent: accent,
//                                 segments: const [
//                                   ButtonSegment(
//                                     value:
//                                         AudioRepeatMode
//                                             .off,
//                                     icon: Icon(
//                                       Icons
//                                           .repeat_rounded,
//                                     ),
//                                     label:
//                                         Text('Off'),
//                                   ),
//                                   ButtonSegment(
//                                     value:
//                                         AudioRepeatMode
//                                             .all,
//                                     icon: Icon(
//                                       Icons
//                                           .repeat_rounded,
//                                     ),
//                                     label:
//                                         Text('All'),
//                                   ),
//                                   ButtonSegment(
//                                     value:
//                                         AudioRepeatMode
//                                             .one,
//                                     icon: Icon(
//                                       Icons
//                                           .repeat_one_rounded,
//                                     ),
//                                     label:
//                                         Text('One'),
//                                   ),
//                                 ],
//                                 selected: {
//                                   audioLibrary.repeatMode,
//                                 },
//                                 onSelectionChanged:
//                                     (selection) {
//                                   audioLibrary
//                                       .setRepeatMode(
//                                     selection.first,
//                                   );
//                                 },
//                               ),

//                               const SizedBox(
//                                 height: 38,
//                               ),

//                               // ==================================================
//                               // LIBRARY
//                               // ==================================================

//                               const _SectionTitle(
//                                 title: 'Library',
//                               ),

//                               const SizedBox(
//                                 height: 16,
//                               ),

//                               _NavigationSettingRow(
//                                 icon:
//                                     Icons
//                                         .folder_open_rounded,
//                                 title: 'Add tracks',
//                                 subtitle:
//                                     'Choose music files from your device',
//                                 accent: accent,
//                                 onTap: () =>
//                                     _addTracks(
//                                   context,
//                                 ),
//                               ),

//                               const _SettingsDivider(),

//                               _NavigationSettingRow(
//                                 icon:
//                                     Icons.image_outlined,
//                                 title: 'Home artwork',
//                                 subtitle:
//                                     'Choose an image from your device',
//                                 accent: accent,
//                                 onTap: () =>
//                                     _changeHomeImage(
//                                   context,
//                                 ),
//                               ),

//                               const SizedBox(
//                                 height: 34,
//                               ),

//                               // ==================================================
//                               // EXCLUDE FROM LIBRARY
//                               // ==================================================

//                               const _SubsectionTitle(
//                                 title:
//                                     'Exclude from library',
//                               ),

//                               const SizedBox(
//                                 height: 8,
//                               ),

//                               _ExclusionSwitch(
//                                 extension: 'mp3',
//                                 controller:
//                                     audioLibrary,
//                                 accent: accent,
//                               ),

//                               const _SettingsDivider(),

//                               _ExclusionSwitch(
//                                 extension: 'wav',
//                                 controller:
//                                     audioLibrary,
//                                 accent: accent,
//                               ),

//                               const _SettingsDivider(),

//                               _ExclusionSwitch(
//                                 extension: 'flac',
//                                 controller:
//                                     audioLibrary,
//                                 accent: accent,
//                               ),

//                               const _SettingsDivider(),

//                               _ExclusionSwitch(
//                                 extension: 'm4a',
//                                 controller:
//                                     audioLibrary,
//                                 accent: accent,
//                               ),

//                               const _SettingsDivider(),

//                               _SwitchSettingRow(
//                                 icon: Icons
//                                     .visibility_off_outlined,
//                                 title:
//                                     'Hidden files',
//                                 subtitle:
//                                     'Hide files in dot folders',
//                                 value: audioLibrary
//                                     .excludeHiddenFiles,
//                                 accent: accent,
//                                 onChanged: audioLibrary
//                                     .setExcludeHiddenFiles,
//                               ),

//                               const SizedBox(
//                                 height: 34,
//                               ),

//                               // ==================================================
//                               // MANAGE
//                               // ==================================================

//                               const _SectionTitle(
//                                 title: 'Manage',
//                               ),

//                               const SizedBox(
//                                 height: 12,
//                               ),

//                               _NavigationSettingRow(
//                                 icon: Icons
//                                     .library_music_outlined,
//                                 title:
//                                     '${audioLibrary.tracks.length} tracks in library',
//                                 subtitle:
//                                     'Add, remove, and manage your music',
//                                 accent: accent,
//                                 onTap: () =>
//                                     Navigator.of(
//                                       context,
//                                     ).push(
//                                   MaterialPageRoute(
//                                     builder: (_) =>
//                                         LibraryPage(
//                                       themeProvider:
//                                           themeProvider,
//                                       audioLibrary:
//                                           audioLibrary,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ==========================================================
//                 // PINNED BACK BUTTON
//                 // ==========================================================

//                 Positioned(
//                   top: 12,
//                   left: horizontalPadding - 5,
//                   child: SafeArea(
//                     bottom: false,
//                     child: _PinnedBackButton(
//                       accent: accent,
//                       onPressed: () =>
//                           Navigator.of(context).pop(),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Future<void> _addTracks(
//     BuildContext context,
//   ) async {
//     final added =
//         await audioLibrary.importAudioFiles();

//     if (!context.mounted) return;

//     final message =
//         audioLibrary.errorMessage ??
//             (added
//                 ? 'Tracks added to your library.'
//                 : 'No tracks selected.');

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   Future<void> _changeHomeImage(
//     BuildContext context,
//   ) async {
//     final changed =
//         await audioLibrary.pickHomeImage();

//     if (!context.mounted) return;

//     final message =
//         audioLibrary.errorMessage ??
//             (changed
//                 ? 'Home artwork updated.'
//                 : 'No image was selected.');

//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   static double _responsiveValue(
//     double width, {
//     required double mobile,
//     required double tablet,
//     required double desktop,
//   }) {
//     if (width >= 1100) {
//       return desktop;
//     }

//     if (width >= 700) {
//       return tablet;
//     }

//     return mobile;
//   }
// }

// // ============================================================================
// // HEADER
// // ============================================================================

// class _SettingsHeader
//     extends StatelessWidget {
//   const _SettingsHeader({
//     required this.accent,
//   });

//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final theme =
//         Theme.of(context);

//     return Row(
//       children: [
//         const SizedBox(
//           width: 48,
//         ),

//         Expanded(
//           child: Text(
//             'Settings',
//             style:
//                 theme.textTheme.headlineMedium
//                     ?.copyWith(
//               fontWeight:
//                   FontWeight.w900,
//               letterSpacing:
//                   -0.8,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // SECTION TITLE
// // ============================================================================

// class _SectionTitle
//     extends StatelessWidget {
//   const _SectionTitle({
//     required this.title,
//   });

//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Row(
//       children: [
//         Text(
//           title,
//           style: Theme.of(context)
//               .textTheme
//               .titleLarge
//               ?.copyWith(
//                 fontWeight:
//                     FontWeight.w800,
//                 letterSpacing:
//                     -0.3,
//               ),
//         ),

//         const SizedBox(
//           width: 14,
//         ),

//         Expanded(
//           child: Container(
//             height: 1,
//             color: colors
//                 .onSurface
//                 .withValues(
//               alpha: 0.08,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // SMALL SUBSECTION TITLE
// // ============================================================================

// class _SubsectionTitle
//     extends StatelessWidget {
//   const _SubsectionTitle({
//     required this.title,
//   });

//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Padding(
//       padding:
//           const EdgeInsets.only(
//         left: 4,
//       ),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: colors
//               .onSurface
//               .withValues(
//             alpha: 0.58,
//           ),
//           fontSize: 14,
//           fontWeight:
//               FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // INFORMATION ROW
// // ============================================================================

// class _SettingInfoRow
//     extends StatelessWidget {
//   const _SettingInfoRow({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.accent,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Row(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         _SettingIcon(
//           icon: icon,
//           accent: accent,
//         ),

//         const SizedBox(
//           width: 14,
//         ),

//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(
//                 height: 4,
//               ),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: colors
//                       .onSurface
//                       .withValues(
//                     alpha: 0.58,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // SWITCH ROW
// // ============================================================================

// class _SwitchSettingRow
//     extends StatelessWidget {
//   const _SwitchSettingRow({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.value,
//     required this.onChanged,
//     required this.accent,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final bool value;
//   final ValueChanged<bool> onChanged;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Row(
//       children: [
//         _SettingIcon(
//           icon: icon,
//           accent: accent,
//           active: value,
//         ),

//         const SizedBox(
//           width: 14,
//         ),

//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(
//                 height: 4,
//               ),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: colors
//                       .onSurface
//                       .withValues(
//                     alpha: 0.58,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(
//           width: 10,
//         ),

//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: Colors.white,
//           activeTrackColor: accent,
//           inactiveThumbColor:
//               colors.onSurface
//                   .withValues(
//             alpha: 0.55,
//           ),
//           inactiveTrackColor:
//               colors.onSurface
//                   .withValues(
//             alpha: 0.10,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================================================
// // NAVIGATION ROW
// // ============================================================================

// class _NavigationSettingRow
//     extends StatelessWidget {
//   const _NavigationSettingRow({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     required this.accent,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius:
//             BorderRadius.circular(18),
//         onTap: onTap,
//         child: Padding(
//           padding:
//               const EdgeInsets.symmetric(
//             vertical: 12,
//             horizontal: 4,
//           ),
//           child: Row(
//             children: [
//               _SettingIcon(
//                 icon: icon,
//                 accent: accent,
//               ),

//               const SizedBox(
//                 width: 14,
//               ),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       maxLines: 1,
//                       overflow:
//                           TextOverflow.ellipsis,
//                       style:
//                           const TextStyle(
//                         fontSize: 16,
//                         fontWeight:
//                             FontWeight.w700,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 4,
//                     ),

//                     Text(
//                       subtitle,
//                       maxLines: 2,
//                       overflow:
//                           TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: colors
//                             .onSurface
//                             .withValues(
//                           alpha: 0.58,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(
//                 width: 12,
//               ),

//               Icon(
//                 Icons
//                     .chevron_right_rounded,
//                 size: 23,
//                 color: colors
//                     .onSurface
//                     .withValues(
//                   alpha: 0.55,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // ICON
// // ============================================================================

// class _SettingIcon
//     extends StatelessWidget {
//   const _SettingIcon({
//     required this.icon,
//     required this.accent,
//     this.active = false,
//   });

//   final IconData icon;
//   final Color accent;
//   final bool active;

//   @override
//   Widget build(BuildContext context) {
//     final isDark =
//         Theme.of(context).brightness ==
//             Brightness.dark;

//     return AnimatedContainer(
//       duration:
//           const Duration(milliseconds: 350),
//       width: 42,
//       height: 42,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: accent.withValues(
//           alpha: active
//               ? 0.16
//               : isDark
//                   ? 0.065
//                   : 0.055,
//         ),
//       ),
//       child: Icon(
//         icon,
//         size: 21,
//         color: active
//             ? accent
//             : Theme.of(context)
//                 .colorScheme
//                 .onSurface
//                 .withValues(
//                   alpha: 0.75,
//                 ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // SEGMENTED CONTROL
// // ============================================================================

// class _AccentSegmentedButton<T>
//     extends StatelessWidget {
//   const _AccentSegmentedButton({
//     required this.accent,
//     required this.segments,
//     required this.selected,
//     required this.onSelectionChanged,
//   });

//   final Color accent;
//   final List<ButtonSegment<T>> segments;
//   final Set<T> selected;
//   final ValueChanged<Set<T>>
//       onSelectionChanged;

//   @override
//   Widget build(BuildContext context) {
//     final theme =
//         Theme.of(context);

//     final scheme =
//         theme.colorScheme.copyWith(
//       primary: accent,
//       secondary: accent,
//     );

//     return Theme(
//       data: theme.copyWith(
//         colorScheme: scheme,
//       ),
//       child: SizedBox(
//         width: double.infinity,
//         child: SegmentedButton<T>(
//           segments: segments,
//           selected: selected,
//           onSelectionChanged:
//               onSelectionChanged,
//           showSelectedIcon: false,
//           style: ButtonStyle(
//             minimumSize:
//                 const WidgetStatePropertyAll(
//               Size.fromHeight(50),
//             ),
//             padding:
//                 const WidgetStatePropertyAll(
//               EdgeInsets.symmetric(
//                 horizontal: 8,
//               ),
//             ),
//             shape:
//                 WidgetStatePropertyAll(
//               RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(
//                   28,
//                 ),
//               ),
//             ),
//             side:
//                 WidgetStatePropertyAll(
//               BorderSide(
//                 color: theme
//                     .colorScheme
//                     .onSurface
//                     .withValues(
//                   alpha: 0.09,
//                 ),
//               ),
//             ),
//             backgroundColor:
//                 WidgetStatePropertyAll(
//               theme
//                   .colorScheme
//                   .onSurface
//                   .withValues(
//                 alpha: 0.035,
//               ),
//             ),
//             foregroundColor:
//                 WidgetStatePropertyAll(
//               theme
//                   .colorScheme
//                   .onSurface
//                   .withValues(
//                 alpha: 0.72,
//               ),
//             ),
//             overlayColor:
//                 WidgetStatePropertyAll(
//               accent.withValues(
//                 alpha: 0.08,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // EXCLUSION SWITCH
// // ============================================================================

// class _ExclusionSwitch
//     extends StatelessWidget {
//   const _ExclusionSwitch({
//     required this.extension,
//     required this.controller,
//     required this.accent,
//   });

//   final String extension;
//   final AudioLibraryController controller;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final excluded =
//         controller.excludedExtensions
//             .contains(extension);

//     final colors =
//         Theme.of(context)
//             .colorScheme;

//     return Padding(
//       padding:
//           const EdgeInsets.symmetric(
//         vertical: 2,
//         horizontal: 4,
//       ),
//       child: Row(
//         children: [
//           _SettingIcon(
//             icon:
//                 Icons.audio_file_outlined,
//             accent: accent,
//             active: excluded,
//           ),

//           const SizedBox(
//             width: 14,
//           ),

//           Expanded(
//             child: Text(
//               '.$extension files',
//               style:
//                   const TextStyle(
//                 fontSize: 15,
//                 fontWeight:
//                     FontWeight.w600,
//               ),
//             ),
//           ),

//           Switch(
//             value: excluded,
//             onChanged: (value) {
//               controller
//                   .setExtensionExcluded(
//                 extension,
//                 value,
//               );
//             },
//             activeColor: Colors.white,
//             activeTrackColor: accent,
//             inactiveThumbColor:
//                 colors.onSurface
//                     .withValues(
//               alpha: 0.55,
//             ),
//             inactiveTrackColor:
//                 colors.onSurface
//                     .withValues(
//               alpha: 0.10,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================================
// // DIVIDER
// // ============================================================================

// class _SettingsDivider
//     extends StatelessWidget {
//   const _SettingsDivider();

//   @override
//   Widget build(BuildContext context) {
//     final color =
//         Theme.of(context)
//             .colorScheme
//             .onSurface;

//     return Padding(
//       padding:
//           const EdgeInsets.only(
//         left: 60,
//       ),
//       child: Divider(
//         height: 1,
//         thickness: 0.6,
//         color: color.withValues(
//           alpha: 0.075,
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // PINNED BACK BUTTON
// // ============================================================================

// class _PinnedBackButton
//     extends StatelessWidget {
//   const _PinnedBackButton({
//     required this.onPressed,
//     required this.accent,
//   });

//   final VoidCallback onPressed;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     final isDark =
//         Theme.of(context).brightness ==
//             Brightness.dark;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius:
//             BorderRadius.circular(18),
//         child: AnimatedContainer(
//           duration:
//               const Duration(milliseconds: 400),
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: accent.withValues(
//               alpha:
//                   isDark ? 0.11 : 0.08,
//             ),
//             border: Border.all(
//               color: Colors.white.withValues(
//                 alpha:
//                     isDark ? 0.07 : 0.12,
//               ),
//             ),
//           ),
//           child: Icon(
//             Icons
//                 .arrow_back_ios_new_rounded,
//             size: 17,
//             color: Theme.of(context)
//                 .colorScheme
//                 .onSurface
//                 .withValues(
//               alpha: 0.86,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // EDGE SWIPE BACK
// // ============================================================================

// class _EdgeSwipeBack
//     extends StatefulWidget {
//   const _EdgeSwipeBack({
//     required this.child,
//   });

//   final Widget child;

//   @override
//   State<_EdgeSwipeBack> createState() =>
//       _EdgeSwipeBackState();
// }

// class _EdgeSwipeBackState
//     extends State<_EdgeSwipeBack> {
//   double _startX = 0;
//   double _currentX = 0;
//   bool _tracking = false;

//   void _onPointerDown(
//     PointerDownEvent event,
//   ) {
//     if (event.position.dx <= 28) {
//       _startX = event.position.dx;
//       _currentX = _startX;
//       _tracking = true;
//     }
//   }

//   void _onPointerMove(
//     PointerMoveEvent event,
//   ) {
//     if (!_tracking) return;

//     _currentX = event.position.dx;

//     if (_currentX - _startX > 100) {
//       _tracking = false;

//       if (mounted) {
//         Navigator.of(context).maybePop();
//       }
//     }
//   }

//   void _onPointerUp(
//     PointerUpEvent event,
//   ) {
//     _tracking = false;
//   }

//   void _onPointerCancel(
//     PointerCancelEvent event,
//   ) {
//     _tracking = false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Listener(
//       onPointerDown:
//           _onPointerDown,
//       onPointerMove:
//           _onPointerMove,
//       onPointerUp:
//           _onPointerUp,
//       onPointerCancel:
//           _onPointerCancel,
//       child: widget.child,
//     );
//   }
// }
