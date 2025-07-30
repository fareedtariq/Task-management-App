import 'package:flutter/material.dart';
import 'LocalNotificationManager.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late LocalNotificationManager localNotificationManager; // Use 'late' here

  @override
  void initState() {
    super.initState();
    localNotificationManager = LocalNotificationManager(); // Initialize in initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            localNotificationManager.showNotification();
          },
          child: Text('Show Notification'),
        ),
      ),
    );
  }
}
