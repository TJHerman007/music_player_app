import 'package:flutter/material.dart';

import 'audio_processor.dart';

/// Minimal effects panel designed to inherit the app's existing ThemeData.
///
/// No fixed light/dark colors are used here: Theme.of(context) supplies the
/// current app palette and now-playing accent.
class AudioEffectsSheet extends StatelessWidget {
  const AudioEffectsSheet({super.key, required this.processor});

  final AudioProcessor processor;

  static Future<void> show(
    BuildContext context, {
    required AudioProcessor processor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioEffectsSheet(processor: processor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;

    return SafeArea(
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ListenableBuilder(
          listenable: processor,
          builder: (context, _) {
            final effects = processor.effects;
            final spatial = processor.spatial;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Audio effects',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reset',
                        onPressed: processor.reset,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),

                  Text(
                    'Fine-tune the sound without changing your library.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: .55),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _SectionTitle(
                    icon: Icons.speed_rounded,
                    title: 'Speed',
                    value: '${effects.speed.toStringAsFixed(2)}×',
                  ),

                  Slider(
                    value: effects.speed,
                    min: .5,
                    max: 2,
                    divisions: 30,
                    activeColor: accent,
                    onChanged: effects.setSpeed,
                  ),

                  _ScaleLabels(labels: const ['0.50×', '1.00×', '2.00×']),

                  const SizedBox(height: 28),

                  _SectionTitle(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Pitch',
                    value:
                        '${effects.pitchSemitones >= 0 ? '+' : ''}'
                        '${effects.pitchSemitones.toStringAsFixed(1)} st',
                  ),

                  Slider(
                    value: effects.pitchSemitones,
                    min: -12,
                    max: 12,
                    divisions: 48,
                    activeColor: accent,
                    onChanged: effects.setPitch,
                  ),

                  _ScaleLabels(labels: const ['−12', '0', '+12']),

                  const SizedBox(height: 22),

                  _EffectTile(
                    icon: Icons.spatial_audio_rounded,
                    title: 'Spatial audio',
                    subtitle: 'Wider and more immersive',
                    value: spatial.enabled,
                    onChanged: spatial.setEnabled,
                  ),

                  if (spatial.enabled) ...[
                    const SizedBox(height: 4),
                    Slider(
                      value: spatial.strength,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      activeColor: accent,
                      onChanged: spatial.setStrength,
                    ),
                  ],

                  _EffectTile(
                    icon: Icons.mic_off_rounded,
                    title: 'Karaoke',
                    subtitle: processor.karaokeEnabled
                        ? 'Vocal reduction is active'
                        : 'Reduce centered vocals',
                    value: processor.karaokeEnabled,
                    onChanged: (_) {
                      // The actual enable/disable operation requires the
                      // controller to supply the resolved original path.
                      // See the integration note below.
                    },
                  ),

                  if (processor.karaokeEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Karaoke is using a cached processed version.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: .52),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ScaleLabels extends StatelessWidget {
  const _ScaleLabels({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 10.5,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45),
    );

    return Row(
      children: [
        Text(labels[0], style: style),
        const Spacer(),
        Text(labels[1], style: style),
        const Spacer(),
        Text(labels[2], style: style),
      ],
    );
  }
}

class _EffectTile extends StatelessWidget {
  const _EffectTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
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
