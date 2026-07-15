import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_log.dart';

/// StorageService manages habits and their daily completion logs
/// This is a simple in-memory implementation for the prototype
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal() {
    _initializeSampleData();
  }

  final List<Habit> _habits = [
    Habit(
      id: '1',
      name: 'Drink water',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Habit(
      id: '2',
      name: 'Read',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Habit(
      id: '3',
      name: 'Exercise',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Habit(
      id: '4',
      name: 'Meditate',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  final List<HabitLog> _habitLogs = [];

  void _initializeSampleData() {
    final now = DateTime.now();

    // Drink water logs (habit 1): M T W T completed, F S S not completed
    _habitLogs.addAll([
      HabitLog(id: '1', habitId: '1', date: _getDateForDay(now, 0), completed: true), // Mon
      HabitLog(id: '2', habitId: '1', date: _getDateForDay(now, 1), completed: true), // Tue
      HabitLog(id: '3', habitId: '1', date: _getDateForDay(now, 2), completed: false), // Wed
      HabitLog(id: '4', habitId: '1', date: _getDateForDay(now, 3), completed: true), // Thu
      HabitLog(id: '5', habitId: '1', date: _getDateForDay(now, 4), completed: false), // Fri
      HabitLog(id: '6', habitId: '1', date: _getDateForDay(now, 5), completed: false), // Sat
      HabitLog(id: '7', habitId: '1', date: _getDateForDay(now, 6), completed: false), // Sun
    ]);

    // Read logs (habit 2): All completed except Sunday
    _habitLogs.addAll([
      HabitLog(id: '8', habitId: '2', date: _getDateForDay(now, 0), completed: true), // Mon
      HabitLog(id: '9', habitId: '2', date: _getDateForDay(now, 1), completed: true), // Tue
      HabitLog(id: '10', habitId: '2', date: _getDateForDay(now, 2), completed: true), // Wed
      HabitLog(id: '11', habitId: '2', date: _getDateForDay(now, 3), completed: true), // Thu
      HabitLog(id: '12', habitId: '2', date: _getDateForDay(now, 4), completed: true), // Fri
      HabitLog(id: '13', habitId: '2', date: _getDateForDay(now, 5), completed: false), // Sat
      HabitLog(id: '14', habitId: '2', date: _getDateForDay(now, 6), completed: false), // Sun
    ]);

    // Exercise logs (habit 3): Wed and Thu completed, Wed completed again for second time
    _habitLogs.addAll([
      HabitLog(id: '15', habitId: '3', date: _getDateForDay(now, 0), completed: false), // Mon
      HabitLog(id: '16', habitId: '3', date: _getDateForDay(now, 1), completed: false), // Tue
      HabitLog(id: '17', habitId: '3', date: _getDateForDay(now, 2), completed: true), // Wed
      HabitLog(id: '18', habitId: '3', date: _getDateForDay(now, 3), completed: false), // Thu
      HabitLog(id: '19', habitId: '3', date: _getDateForDay(now, 4), completed: true), // Fri
      HabitLog(id: '20', habitId: '3', date: _getDateForDay(now, 5), completed: false), // Sat
      HabitLog(id: '21', habitId: '3', date: _getDateForDay(now, 6), completed: false), // Sun
    ]);

    // Meditate logs (habit 4): Mon-Sat completed, Sun not
    _habitLogs.addAll([
      HabitLog(id: '22', habitId: '4', date: _getDateForDay(now, 0), completed: true), // Mon
      HabitLog(id: '23', habitId: '4', date: _getDateForDay(now, 1), completed: true), // Tue
      HabitLog(id: '24', habitId: '4', date: _getDateForDay(now, 2), completed: true), // Wed
      HabitLog(id: '25', habitId: '4', date: _getDateForDay(now, 3), completed: true), // Thu
      HabitLog(id: '26', habitId: '4', date: _getDateForDay(now, 4), completed: true), // Fri
      HabitLog(id: '27', habitId: '4', date: _getDateForDay(now, 5), completed: true), // Sat
      HabitLog(id: '28', habitId: '4', date: _getDateForDay(now, 6), completed: false), // Sun
    ]);
  }

  /// Get the date for a specific day of the week
  /// dayOffset: 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
  DateTime _getDateForDay(DateTime reference, int dayOffset) {
    // Find Monday of the current week
    final weekday = reference.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = weekday - 1;
    final monday = reference.subtract(Duration(days: daysFromMonday));
    return monday.add(Duration(days: dayOffset));
  }

  /// Get all habits
  List<Habit> getAllHabits() {
    return List.from(_habits);
  }

  /// Get all habit logs for a specific habit
  List<HabitLog> getHabitLogsForHabit(String habitId) {
    return _habitLogs
        .where((log) => log.habitId == habitId)
        .toList();
  }

  /// Get habit logs for a specific habit and date range
  List<HabitLog> getHabitLogsForDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _habitLogs
        .where((log) =>
            log.habitId == habitId &&
            log.date.isAfter(startDate) &&
            log.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Add a new habit
  void addHabit(Habit habit) {
    _habits.add(habit);
  }

  /// Update a habit
  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      _habits[index] = habit;
    }
  }

  /// Delete a habit
  void deleteHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    _habitLogs.removeWhere((log) => log.habitId == habitId);
  }

  /// Log a habit completion
  void logHabitCompletion(String habitId, DateTime date, bool completed) {
    final existingIndex = _habitLogs.indexWhere((log) =>
        log.habitId == habitId &&
        log.date.year == date.year &&
        log.date.month == date.month &&
        log.date.day == date.day);

    if (existingIndex >= 0) {
      _habitLogs[existingIndex] = HabitLog(
        id: _habitLogs[existingIndex].id,
        habitId: habitId,
        date: date,
        completed: completed,
      );
    } else {
      _habitLogs.add(
        HabitLog(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          habitId: habitId,
          date: date,
          completed: completed,
        ),
      );
    }
  }

  /// Calculate streak for a habit
  int getStreakCount(String habitId) {
    final logs = getHabitLogsForHabit(habitId);
    if (logs.isEmpty) return 0;

    logs.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDate;

    for (final log in logs) {
      if (!log.completed) continue;

      if (lastDate == null) {
        lastDate = log.date;
        streak = 1;
      } else {
        final daysDifference = lastDate.difference(log.date).inDays;
        if (daysDifference == 1) {
          streak++;
          lastDate = log.date;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
