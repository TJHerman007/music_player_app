import 'package:flutter/material.dart';

import 'audio_engine.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({required this.audioEngine, super.key});

  final AudioEngine audioEngine;

  static const _labels = [
    '60', '120', '250', '500', '1k',
    '2k', '4k', '8k', '12k', '16k',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioEngine,
      builder: (context, _) {
        final effects = audioEngine.effects;
        return Scaffold(
          appBar: AppBar(
            title: const Text('10-band Equalizer'),
            actions: [
              IconButton(
                tooltip: 'Flat',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => audioEngine.setEq(
                  List<double>.filled(10, 0),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('-12 dB',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .55),
                          )),
                      Text('0 dB',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .55),
                          )),
                      Text('+12 dB',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .55),
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(10, (i) {
                        final value = effects.eq[i];
                        return Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: value.clamp(-12, 12),
                                    min: -12,
                                    max: 12,
                                    divisions: 48,
                                    onChanged: (v) =>
                                        audioEngine.setEqBand(i, v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _labels[i],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                value == 0
                                    ? '0'
                                    : '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
