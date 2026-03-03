class Session {
  final int? id;
  final String title;
  final String date;
  final String time;
  final String duration;
  final String distance;
  final String avgSpeed;

  Session({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    required this.distance,
    required this.avgSpeed,
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
    );
  }
}
