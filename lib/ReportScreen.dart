import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'task.dart'; // Import the Task model
import 'database_helper.dart'; // Assuming you have a DatabaseHelper to handle database operations

class ReportScreen extends StatefulWidget {
  final List<Task> tasks;

  ReportScreen({Key? key, required this.tasks}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Task> _tasks = []; // List to hold tasks loaded from the database

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Initialize tasks by loading from the database
  }

  // Method to fetch all tasks from the database
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

  // Method to load tasks from the database and set them in the state
  Future<void> _loadTasks() async {
    final tasks = await getAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Count the number of completed and pending tasks
    int completedTasks = _tasks.where((task) => task.isCompleted).length;
    int pendingTasks = _tasks.length - completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chart
            Container(
              height: 250,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        y: completedTasks.toDouble(),
                        colors: [Colors.green],
                        width: 20,
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        y: pendingTasks.toDouble(),
                        colors: [Colors.red],
                        width: 20,
                      ),
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(showTitles: true, getTitles: (value) {
                      if (value == 0) {
                        return 'Completed';
                      } else if (value == 1) {
                        return 'Pending';
                      }
                      return '';
                    }),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Text below the chart
            Text(
              'Pending Tasks: $pendingTasks\nCompleted Tasks: $completedTasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
