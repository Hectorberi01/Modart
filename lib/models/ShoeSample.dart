class ShoeSample {
  final int steps;
  final double angleX;
  final double angleY;
  final bool badPosition;
  final DateTime timestamp;

  // Extended ESP32 data
  final int? espTimestamp;
  final double? distanceM;
  final double? ax, ay, az;
  final double? gx, gy, gz;
  final double? mag;
  final double? delta;
  final double? poidsTalon;
  final double? poidsAvantpied;

  ShoeSample({
    required this.steps,
    required this.angleX,
    required this.angleY,
    required this.badPosition,
    required this.timestamp,
    this.espTimestamp,
    this.distanceM,
    this.ax,
    this.ay,
    this.az,
    this.gx,
    this.gy,
    this.gz,
    this.mag,
    this.delta,
    this.poidsTalon,
    this.poidsAvantpied,
  });

  @override
  String toString() {
    return 'ShoeSample(steps: $steps, angleX: $angleX, angleY: $angleY, badPosition: $badPosition, timestamp: $timestamp)';
  }

  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'angleX': angleX,
      'angleY': angleY,
      'badPosition': badPosition ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SessionResult {
  final int totalSteps;
  final Duration badPostureDuration;
  final double postureScore;

  SessionResult({
    required this.totalSteps,
    required this.badPostureDuration,
    required this.postureScore,
  });
}
