class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
    );
  }
}
