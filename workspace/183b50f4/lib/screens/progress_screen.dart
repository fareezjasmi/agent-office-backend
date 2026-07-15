import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late StorageService _storageService;
  late List<Habit> _habits;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _habits = _storageService.getAllHabits();
    _weekStart = _calculateWeekStart(DateTime.now());
  }

  /// Calculate the Monday of the current week
  /// The ISO week starts on Monday
  DateTime _calculateWeekStart(DateTime date) {
    // weekday: 1 = Monday, 7 = Sunday
    final weekday = date.weekday;
    final daysFromMonday = weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Get the date for a specific day offset from week start
  /// dayOffset: 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
  DateTime _getDateForDayOffset(int dayOffset) {
    return _weekStart.add(Duration(days: dayOffset));
  }

  /// Check if a habit was completed on a specific date
  bool _isHabitCompletedOnDate(String habitId, DateTime date) {
    final logs = _storageService.getHabitLogsForHabit(habitId);
    return logs.any((log) =>
        log.completed &&
        log.date.year == date.year &&
        log.date.month == date.month &&
        log.date.day == date.day);
  }

  /// Build the day headers (M T W T F S S)
  Widget _buildDayHeaders() {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          7,
          (index) => Text(
            dayLabels[index],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Build progress circles for a habit (one circle per day of the week)
  Widget _buildProgressCircles(String habitId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          7,
          (index) {
            final date = _getDateForDayOffset(index);
            final isCompleted = _isHabitCompletedOnDate(habitId, date);

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.black : Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build a single habit row with name, streak, and progress circles
  Widget _buildHabitRow(Habit habit) {
    final streak = _storageService.getStreakCount(habit.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    streak.toString(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressCircles(habit.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This week',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Day Headers (M T W T F S S)
            _buildDayHeaders(),
            const SizedBox(height: 16),

            // Habits List with Progress Circles
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _habits.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildHabitRow(_habits[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/today');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
