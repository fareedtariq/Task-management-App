import 'package:flutter/material.dart';
import 'export_tasks_screen.dart'; // Import the ExportTasksScreen
import 'task.dart'; // Make sure to import Task model if needed
import 'database_helper.dart';
class SettingsScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Function(bool) onThemeToggle;

  SettingsScreen({required this.isDarkTheme, required this.onThemeToggle});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}


class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationSoundOn = true;
  bool _isPermissionGranted = true;
  String _selectedSound = 'Default'; // Store the selected sound
  List<Task> _tasks = [];
  @override
  void initState() {
    super.initState();
    _loadTasks();  // Load tasks on screen initialization
  }
  void _toggleNotificationSound(bool value) {
    setState(() {
      _isNotificationSoundOn = value;
    });
    if (_isNotificationSoundOn) {
      // If notification sound is on, show sound selection dialog
      _showSoundSelectionDialog();
    }
  }
  Future<void> _loadTasks() async {
    final tasks = await getAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }
  Future<List<Task>> getAllTasks() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> taskMaps = await db.query('tasks');

    return List.generate(taskMaps.length, (i) {
      return Task(
        id: taskMaps[i]['id'],
        title: taskMaps[i]['title'],
        description: taskMaps[i]['description'],
        dueDate: taskMaps[i]['dueDate'],
        isCompleted: taskMaps[i]['isCompleted'] == 1,
        repeatFrequency: taskMaps[i]['repeatFrequency'],
      );
    });
  }

  void _togglePermission(bool value) {
    setState(() {
      _isPermissionGranted = value;

    });
  }

  // Updated Export Data function to navigate to the ExportTasksScreen
  void _exportData() {
    // For demonstration, you can pass an empty list or a populated one
    List<Task> tasks = []; // Replace with actual task data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportTasksScreen(tasks: tasks),
      ),
    );
  }

  void _showSoundSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Default'),
              onTap: () {
                setState(() {
                  _selectedSound = 'Default';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Chime'),
              onTap: () {
                setState(() {
                  _selectedSound = 'Chime';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Bell'),
              onTap: () {
                setState(() {
                  _selectedSound = 'Bell';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Ping'),
              onTap: () {
                setState(() {
                  _selectedSound = 'Ping';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Switcher
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: widget.isDarkTheme,
              onChanged: widget.onThemeToggle, // Call the parent function to toggle the theme
            ),
          ),

          // Notification Sound Toggle
          ListTile(
            title: Text('Notification Sound'),
            subtitle: Text('Current sound: $_selectedSound'), // Show selected sound
            trailing: Switch(
              value: _isNotificationSoundOn,
              onChanged: _toggleNotificationSound,
            ),
          ),

          // Permissions Toggle
          ListTile(
            title: Text('Permissions'),
            trailing: Switch(
              value: _isPermissionGranted,
              onChanged: _togglePermission,
            ),
          ),

          // Export Data Button
          ListTile(
            title: Text('Export Data'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExportTasksScreen(tasks: _tasks), // Passing the tasks list
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
