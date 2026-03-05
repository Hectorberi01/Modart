class Session {
  final int? id;
  final String title;
  final String date;
  final String time;
  final String duration;
  final String distance;
  final String avgSpeed;
  final int steps;
  final double postureScore;
  final double globalScore;

  Session({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    required this.distance,
    required this.avgSpeed,
    this.steps = 0,
    this.postureScore = 0,
    this.globalScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'duration': duration,
      'distance': distance,
      'avgSpeed': avgSpeed,
      'steps': steps,
      'postureScore': postureScore,
      'globalScore': globalScore,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      time: map['time'],
      duration: map['duration'],
      distance: map['distance'],
      avgSpeed: map['avgSpeed'],
      steps: (map['steps'] as int?) ?? 0,
      postureScore: (map['postureScore'] as num?)?.toDouble() ?? 0,
      globalScore: (map['globalScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
