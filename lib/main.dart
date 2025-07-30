import 'package:flutter/material.dart';
import 'add_task_screen.dart';
import 'SettingScreen.dart';  // Import Settings Screen
import 'ReportScreen.dart';    // Import Report Screen
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'notification_service.dart';
import 'task.dart';
import 'package:task_manager_app/LocalNotificationManager.dart';
import 'database_helper.dart';
import 'dashboard.dart'; // Importing Dashboard screen

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize notifications
  final InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await NotificationService.init();

  final db = await DatabaseHelper.instance.database;
  await NotificationService.scheduleDailySummary(db);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  // Toggle the theme between dark and light
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager App',
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(onThemeToggle: _toggleTheme, isDarkTheme: _isDarkTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkTheme;

  HomeScreen({required this.onThemeToggle, required this.isDarkTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load tasks when the screen is initialized
  }

  // Fetch tasks from the database
  Future<void> _loadTasks() async {
    final tasks = await getAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  // Get views for navigation
  List<Widget> _getViews() {
    return [
      DashboardScreen(),

      ReportScreen(tasks: _tasks),

      SettingsScreen(isDarkTheme: widget.isDarkTheme, onThemeToggle: widget.onThemeToggle),
    ];
  }

  // Handle tab clicks for BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fetch all tasks from the database
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDarkTheme),
          ),
        ],
      ),
      body: Column(
        children: [
          // Display total tasks in the dashboard

          // Display selected view dynamically based on tab
          Expanded(child: _getViews()[_selectedIndex]),

          // Export button to export tasks

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle tab selection
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );

          if (result is Task) {
            // Add the new task to the database and reload tasks
            await DatabaseHelper.instance.insertTask(result.toMap());
            await _loadTasks(); // Reload tasks after insertion
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
