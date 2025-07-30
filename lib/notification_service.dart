import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'task.dart';
import 'package:permission_handler/permission_handler.dart'; // Added for permission handling
import 'dart:io' show Platform; // Added to check for Android platform

import 'database_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static Timer? _backupTimer; // Backup timer to ensure notification triggers

  // Initialize the notification service
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi')); // Set timezone for Pakistan

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel_id', // Unique channel ID
      'Task Notifications', // User-visible name of the channel
      description: 'Notifications for task reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: initializationSettingsAndroid),
    );
  }

  // Request permission for exact alarms
  static Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      // Check if we are on Android 12 or higher
      if (await Permission.notification.isDenied) {
        // Request permission to send notifications
        await Permission.notification.request();
        await requestExactAlarmPermission();

      }
    }
  }

  // Schedule a notification with a backup timer
  static Future<void> scheduleNotification(DateTime scheduledTime, String title,
      String body) async {
    // Request permission before scheduling notification
    await requestExactAlarmPermission();

    if (scheduledTime.isAfter(DateTime.now())) {
      final localTime = tz.TZDateTime.from(scheduledTime, tz.local);

      print('Scheduling notification at: $localTime');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        localTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_id',
            'Task Notifications',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
            .wallClockTime,
      );

      print('Notification scheduled!');

      // Setup a backup Timer to ensure the notification appears
      final Duration delay = localTime.difference(DateTime.now());
      _backupTimer?.cancel(); // Cancel any existing timer
      _backupTimer = Timer(delay, () {
        print("Triggering backup notification.");
        sendImmediateNotification(title, body);
      });
    } else {
      print('Scheduled time is in the past.');
    }
  }

  // Send an immediate notification as a backup
  static Future<void> sendImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Immediate notification for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      NotificationDetails(android: androidPlatformChannelSpecifics),
    );

    print('Backup notification sent.');
  }

  static Future<void> scheduleDueDateReminder(DateTime dueDate, String taskTitle) async {
    if (dueDate.isAfter(DateTime.now())) {
      DateTime reminderTime = dueDate.subtract(Duration(minutes: 1));
      await scheduleNotification(
          reminderTime, 'Task Reminder', 'Your task "$taskTitle" is due soon!');
    } else {
      print('Due date is in the past.');
    }
  }
  static Future<void> scheduleRecurringReminder(
      DateTime nextDueDate, String taskTitle, String frequency) async {
    RepeatInterval? repeatInterval;

    // Determine the repeat interval based on the frequency
    switch (frequency.toLowerCase()) {
      case 'daily':
        repeatInterval = RepeatInterval.daily;
        break;
      case 'weekly':
        repeatInterval = RepeatInterval.weekly;
        break;
      case 'monthly':
        print('Monthly recurrence is not natively supported.');
        return; // Return early for unsupported intervals
      default:
        print('Invalid frequency');
        return;
    }

    if (repeatInterval != null) {
      // Schedule a recurring notification with the chosen interval
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        0, // Set unique ID for each notification if needed
        'Recurring Task Reminder', // Notification title
        'Your task "$taskTitle" is due again!', // Notification body
        repeatInterval, // Chosen interval (daily or weekly)
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_id', // Unique channel ID for task notifications
            'Task Notifications', // Channel name
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidAllowWhileIdle: true, // Allows notifications even when the app is idle
      );
      print('Recurring notification scheduled with interval: $frequency');
    }
  }

  // Schedule daily summary notification
  static Future<void> scheduleDailySummary(Database db) async {
    DateTime now = DateTime.now();
    DateTime summaryTime = DateTime(now.year, now.month, now.day, 12, 52); // Set to 2:55 PM today
    print('Current time: $now');
    print('Summary time: $summaryTime');

    // Check if the current time is after 2:55 PM
    if (now.isAfter(summaryTime)) {
      // If it has already passed, set the summary time to 2:55 PM tomorrow
      summaryTime = summaryTime.add(Duration(days: 1));
    }

    // Fetch tasks due today from the database
    List<Task> tasksDueToday = await _fetchTasksDueToday(db, now);

    print('Tasks due today: ${tasksDueToday.length}');

    // Create the notification body from the tasks due today
    String body = 'Tasks due today:\n' + tasksDueToday.map((task) => task.title).join('\n');

    // Schedule the notification
    await scheduleNotification(summaryTime, 'Today\'s Tasks', body);
  }

  static Future<List<Task>> _fetchTasksDueToday(Database db, DateTime now) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate = ?',
      whereArgs: [now.toIso8601String().split('T')[0]], // Compare only date part
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }
}
