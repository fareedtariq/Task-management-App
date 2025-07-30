import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationManager {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin; // Use 'late' keyword

  LocalNotificationManager() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Initialize here
    _initialize();
  }

  void _initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel Name
      channelDescription: 'your_channel_description', // Channel Description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notification Title',
      'Notification Body',
      platformChannelSpecifics,
    );
  }
}
