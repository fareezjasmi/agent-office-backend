import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';

/// AddHabitModal is a bottom sheet modal that allows users to create a new habit
/// It validates input and persists the habit to storage when the Add button is pressed
class AddHabitModal extends StatefulWidget {
  /// Callback function that is called when a new habit is successfully added
  /// This allows the parent screen to refresh its state
  final Function(Habit) onHabitAdded;

  const AddHabitModal({
    super.key,
    required this.onHabitAdded,
  });

  @override
  State<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  final TextEditingController _habitNameController = TextEditingController();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _habitNameController.dispose();
    super.dispose();
  }

  /// Validates that the habit name is not empty and adds the habit to storage
  void _addHabit() {
    final habitName = _habitNameController.text.trim();

    // Validate that the habit name is not empty
    if (habitName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit name'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create a new habit with a unique ID and current timestamp
    final newHabit = Habit(
      id: const Uuid().v4(),
      name: habitName,
      createdAt: DateTime.now(),
    );

    // Save the habit to storage
    _storageService.addHabit(newHabit);

    // Call the callback to notify the parent screen
    widget.onHabitAdded(newHabit);

    // Close the modal
    Navigator.of(context).pop();
  }

  /// Closes the modal without saving
  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Semi-transparent dark overlay behind the modal
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small indicator line at the top of the modal
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),

              // Title: "New habit"
              const Text(
                'New habit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Text input field with light gray background
              TextField(
                controller: _habitNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Stretch for 5 minutes',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                autofocus: true,
              ),
              const SizedBox(height: 24),

              // Cancel and Add buttons at the bottom
              Row(
                children: [
                  // Cancel button - light gray background, text button style
                  Expanded(
                    child: TextButton(
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Add button - black background with white text
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
