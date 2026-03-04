import 'package:modar/models/ShoeSample.dart';

class SessionManager {
  final List<ShoeSample> _samples = [];

  void addSample(ShoeSample sample) {
    _samples.add(sample);
  }

  SessionResult compute() {
    if (_samples.isEmpty) {
      return SessionResult(
        totalSteps: 0,
        badPostureDuration: Duration.zero,
        postureScore: 100,
      );
    }

    int totalSteps = _samples.last.steps - _samples.first.steps;

    Duration badDuration = Duration.zero;

    for (int i = 1; i < _samples.length; i++) {
      final prev = _samples[i - 1];
      final curr = _samples[i];

      if (prev.badPosition) {
        badDuration += curr.timestamp.difference(prev.timestamp);
      }
    }

    final totalDuration = _samples.last.timestamp.difference(
      _samples.first.timestamp,
    );

    double score = 100;

    if (totalDuration.inMilliseconds > 0) {
      final ratio = badDuration.inMilliseconds / totalDuration.inMilliseconds;

      score = (1 - ratio) * 100;
    }

    return SessionResult(
      totalSteps: totalSteps,
      badPostureDuration: badDuration,
      postureScore: score,
    );
  }
}
