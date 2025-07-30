import 'dart:async'; // Import the timer package
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'task.dart';

class CompletedTaskScreen extends StatefulWidget {
  @override
  _CompletedTaskScreenState createState() => _CompletedTaskScreenState();
}

class _CompletedTaskScreenState extends State<CompletedTaskScreen> {
  List<Task> completedTasks = [];
  Timer? _timer; // Timer to periodically check completed tasks

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks(); // Fetch tasks when screen is loaded
    _startTaskDeletionTimer(); // Start timer to check task deletion every minute
  }

  // Fetch completed tasks and remove tasks older than 1 minute from their completion time
  Future<void> _fetchCompletedTasks() async {
    final dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> taskMaps = await dbHelper.getCompletedTasks();
    DateTime now = DateTime.now();

    completedTasks.clear(); // Clear the list before updating

    for (var taskMap in taskMaps) {
      Task task = Task.fromMap(taskMap);

      // Convert `completionTime` to DateTime for comparison
      DateTime? taskCompletionTime;
      try {
        taskCompletionTime = task.dueDate; // Assuming you have a completionTime field
      } catch (e) {
        print("Error parsing completion time: $e");
        continue;
      }

      // Check if the task has been completed for more than 1 minute
      if (taskCompletionTime != null && now.difference(taskCompletionTime).inMinutes >= 1) {
        print(taskCompletionTime);
        await dbHelper.deleteTask(task.id!); // Delete task from database after 1 minute
      } else {
        completedTasks.add(task); // Add tasks that are not older than 1 minute
      }
    }

    setState(() {
      // Update the UI after fetching tasks
    });
  }

  // Start a timer to periodically check for tasks to delete every minute
  void _startTaskDeletionTimer() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchCompletedTasks(); // Fetch completed tasks and delete old ones
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when screen is disposed
    super.dispose();
  }

  // Delete task manually
  Future<void> _deleteTask(Task task) async {
    await DatabaseHelper.instance.deleteTask(task.id!);
    _fetchCompletedTasks(); // Refresh the list after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Completed Tasks',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
      body: completedTasks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: completedTasks.length,
        itemBuilder: (context, index) {
          final task = completedTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  // Card for each task with delete button
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(Icons.check_circle, color: Colors.green, size: 30),
        title: Text(
          task.title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          task.description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteTask(task), // Delete task when tapped
        ),
      ),
    );
  }

  // Widget for empty state when no tasks are completed
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/9.png', // Placeholder for an empty state image
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 16),
          Text(
            'No completed tasks found!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
