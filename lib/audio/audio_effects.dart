import 'package:flutter/foundation.dart';

class AudioEffects extends ChangeNotifier {
  double _speed = 1.0;
  double _pitchSemitones = 0.0;

  // 10-band graphic EQ, in dB.
  final List<double> _eq = List<double>.filled(10, 0.0);

  double get speed => _speed;
  double get pitchSemitones => _pitchSemitones;
  List<double> get eq => List.unmodifiable(_eq);

  static const frequencies = <double>[
    60, 120, 250, 500, 1000, 2000, 4000, 8000, 12000, 16000
  ];

  void setSpeed(double value) {
    _speed = value.clamp(0.5, 2.0);
    notifyListeners();
  }

  void setPitch(double value) {
    _pitchSemitones = value.clamp(-12.0, 12.0);
    notifyListeners();
  }

  void setEqBand(int index, double db) {
    if (index < 0 || index >= _eq.length) return;
    _eq[index] = db.clamp(-12.0, 12.0);
    notifyListeners();
  }

  void setEq(List<double> values) {
    for (var i = 0; i < _eq.length && i < values.length; i++) {
      _eq[i] = values[i].clamp(-12.0, 12.0);
    }
    notifyListeners();
  }

  void reset() {
    _speed = 1.0;
    _pitchSemitones = 0.0;
    for (var i = 0; i < _eq.length; i++) {
      _eq[i] = 0.0;
    }
    notifyListeners();
  }

  void flat() => reset();

  void bassBoost() {
    setEq(const [5, 4, 3, 1, 0, 0, -1, -1, -1, -1]);
  }

  void vocal() {
    setEq(const [-2, -1, 0, 2, 3, 3, 2, 1, 0, -1]);
  }

  void rock() {
    setEq(const [4, 3, 1, -1, -2, 1, 3, 4, 4, 3]);
  }

  void pop() {
    setEq(const [2, 1, 0, -1, -1, 1, 2, 3, 2, 2]);
  }
}
