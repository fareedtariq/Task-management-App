import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Ensure this package is included in pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_app/today_task_screen.dart';
import 'database_helper.dart';
import 'task.dart';
import 'repeated_task_screen.dart';
import 'completed_task_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int completedTasks = 0;
  int todayTasks = 0;
  int recurringTasks = 0;
  int taskStreak = 0;
  String quoteOfTheDay = '';
  final List<Map<String, String>> quoteImages = [
    {"quote": "Believe you can and you're halfway there.", "image": 'assets/13.png'},
    {"quote": "The only limit to our realization of tomorrow is our doubts of today.", "image": 'assets/2.png'},
    {"quote": "Success is not final; failure is not fatal.", "image": 'assets/8.png'},
    {"quote": "Act as if what you do makes a difference. It does.", "image": 'assets/10.png'},
    {"quote": "Don't watch the clock; do what it does. Keep going.", "image": 'assets/14.png'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _setQuoteOfTheDay();
  }

  Future<void> _fetchDashboardData() async {
    final dbHelper = DatabaseHelper.instance;
    String todayDate = DateTime.now().toIso8601String().split('T')[0]; // Get today's date in yyyy-MM-dd format

    List<Map<String, dynamic>> taskMaps = await dbHelper.getTasks();
    setState(() {
      completedTasks = taskMaps.where((task) => Task.fromMap(task).isCompleted).length;

      // Check if the due date of each task matches today's date
      todayTasks = taskMaps.where((task) {
        DateTime taskDueDate = Task.fromMap(task).dueDate; // Assume dueDate is a string in yyyy-MM-dd format
        return taskDueDate == todayDate; // Compare the task due date with today's date
      }).length;

      recurringTasks = taskMaps.where((task) => Task.fromMap(task).repeatFrequency != null && Task.fromMap(task).repeatFrequency != 'None').length;
    });

    await _updateTaskStreak(taskMaps);
  }


  Future<void> _updateTaskStreak(List<Map<String, dynamic>> taskMaps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastCompletedDay = prefs.getInt('lastCompletedDay') ?? 0;
    int streak = prefs.getInt('taskStreak') ?? 0;
    int today = DateTime.now().day;

    if (completedTasks > 0 && lastCompletedDay != today) {
      if (today - lastCompletedDay == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
      prefs.setInt('taskStreak', streak);
      prefs.setInt('lastCompletedDay', today);
    }

    setState(() {
      taskStreak = streak;
    });
  }

  void _setQuoteOfTheDay() {
    List<String> quotes = [
      "Believe you can and you're halfway there.",
      "The only limit to our realization of tomorrow is our doubts of today.",
      "Success is not final; failure is not fatal.",
      "Act as if what you do makes a difference.",
      "Don't watch the clock; do what it does. Keep going."
    ];
    int quoteIndex = DateTime.now().day % quotes.length;
    setState(() {
      quoteOfTheDay = quotes[quoteIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(  // Wrap the Column inside SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Streak Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                  SizedBox(width: 8),
                  Text('Task Streak: $taskStreak days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),

              // Task Overview Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DashboardCard(title: 'Completed Tasks', value: completedTasks.toString(), icon: Icons.check_circle, color: Colors.green, targetScreen: CompletedTaskScreen()),
                  DashboardCard(title: 'Tasks Due Today', value: todayTasks.toString(), icon: Icons.today, color: Colors.blue, targetScreen: TodayTaskScreen()),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DashboardCard(title: 'Recurring Tasks', value: recurringTasks.toString(), icon: Icons.repeat, color: Colors.orange, targetScreen: RepeatedTaskScreen()),
                ],
              ),
              SizedBox(height: 32),

              // Quote of the Day Carousel
              CarouselSlider(
                items: quoteImages.map((quoteImage) {
                  String quote = quoteImage['quote']!;
                  String image = quoteImage['image']!;

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(image, fit: BoxFit.cover),
                        ),
                        Positioned(
                          bottom: 0, // Adjusted bottom position
                          left: 16,
                          right: 16,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              child: Text(
                                quote,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  autoPlay: true,
                  height: 280, // Set a more appropriate height for the carousel
                  enlargeCenterPage: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Widget targetScreen; // Target screen for navigation

  DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.targetScreen, // Constructor receives target screen
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the target screen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          width: MediaQuery.of(context).size.width * 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
