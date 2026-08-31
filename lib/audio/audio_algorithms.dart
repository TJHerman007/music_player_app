import 'dart:math' as math;

/// Pure audio calculations. No Flutter UI and no AudioPlayer ownership.
class AudioAlgorithms {
  const AudioAlgorithms._();

  static double clamp(
    double value, {
    double min = 0,
    double max = 1,
  }) {
    return value.clamp(min, max).toDouble();
  }

  static double semitonesToPitchFactor(double semitones) {
    final value = semitones.clamp(-12.0, 12.0);
    return math.pow(2.0, value / 12.0).toDouble();
  }

  static double pitchFactorToSemitones(double factor) {
    if (factor <= 0) return 0;
    return 12 * math.log(factor) / math.ln2;
  }

  static double dbToLinear(double db) {
    return math.pow(10.0, db / 20.0).toDouble();
  }

  static double linearToDb(double linear) {
    if (linear <= 0) return -120;
    return 20 * math.log(linear) / math.ln10;
  }

  static CrossfadeGains equalPowerCrossfade(double progress) {
    final p = clamp(progress);
    return CrossfadeGains(
      outgoing: math.cos(p * math.pi / 2),
      incoming: math.sin(p * math.pi / 2),
    );
  }

  static double progress(Duration position, Duration duration) {
    if (duration <= Duration.zero) return 0;
    return clamp(
      position.inMicroseconds / duration.inMicroseconds,
    );
  }
}

class CrossfadeGains {
  const CrossfadeGains({
    required this.outgoing,
    required this.incoming,
  });

  final double outgoing;
  final double incoming;
}
