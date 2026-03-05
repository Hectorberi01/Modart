import 'dart:async';
import 'dart:math';

import 'package:modar/models/ShoeSample.dart';

class ShoeDataService {
  final _controller = StreamController<ShoeSample>.broadcast();
  Stream<ShoeSample> get stream => _controller.stream;
  final List<ShoeSample> _samples = [];

  Timer? _timer;
  final Random _random = Random();

  int _steps = 0;

  /// longueur moyenne d’une foulée (m)
  /// marche ≈ 0.70 m
  /// course ≈ 1.2 m
  double stepLength = 0.70;

  void addSample(ShoeSample sample) {
    print("Adding sample: $sample");
    _samples.add(sample);
    _controller.add(sample);
    print("pas de la session: ${computeTotalSteps()}");
    print("distance de la session: ${estimateDistanceMeters()}");
    print("cadence de la session: ${estimateCadence()}");
    print("score de posture de la session: ${computePostureScore()}");
    print("score global de la session: ${computeGlobalScore()}");
  }

  Duration get sessionDuration {
    if (_samples.length < 2) return Duration.zero;
    return _samples.last.timestamp.difference(_samples.first.timestamp);
  }

  void resetSession() {
    _samples.clear();
  }

  void dispose() {
    _controller.close();
  }

  /// ---------------------------------------
  /// 1️⃣ Compter les pas d’une session
  /// ---------------------------------------
  int computeTotalSteps() {
    if (_samples.isEmpty) return 0;

    final first = _samples.first.steps;
    final last = _samples.last.steps;

    print("First: $first");
    print("Last: $last");

    return last - first;
  }

  /// ---------------------------------------
  /// 2️⃣ Estimer la distance
  /// ---------------------------------------
  double estimateDistanceMeters() {
    final steps = computeTotalSteps();

    print("Steps: $steps");
    print("Step length: $stepLength");

    return steps * stepLength;
  }

  /// ---------------------------------------
  /// 3️⃣ Estimer la cadence
  /// cadence = pas / minute
  /// ---------------------------------------
  double estimateCadence() {
    if (_samples.length < 2) return 0;

    final duration = _samples.last.timestamp.difference(
      _samples.first.timestamp,
    );

    final minutes = duration.inSeconds / 60;

    if (minutes == 0) return 0;

    final steps = computeTotalSteps();

    print("Steps: $steps");
    print("Minutes: $minutes");

    return steps / minutes;
  }

  /// ---------------------------------------
  /// 4️⃣ Calculer le score de posture
  /// ---------------------------------------
  double computePostureScore() {
    if (_samples.isEmpty) return 100;

    int badCount = 0;

    for (final sample in _samples) {
      if (sample.badPosition) {
        badCount++;
      }
    }

    final ratio = badCount / _samples.length;

    print("Ratio: $ratio");

    return (1 - ratio) * 100;
  }

  /// ---------------------------------------
  /// 5️⃣ Calculer le score global
  /// ---------------------------------------
  double computeGlobalScore() {
    final steps = computeTotalSteps();
    final distance = estimateDistanceMeters();
    final cadence = estimateCadence();
    final posture = computePostureScore();

    // Pondération simple
    final score =
        (posture * 0.4) + (cadence / 200 * 0.3) + (distance / 10000 * 0.3);

    print("Score global: $score");

    return score.clamp(0, 100);
  }

  void stop() {
    _timer?.cancel();
  }
}
