import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Updated version to trigger onUpgrade if needed
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Handle upgrades to ensure columns are added
    );
  }

  // Create table with subtasks field
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      dueDate TEXT,
      isCompleted INTEGER NOT NULL,
      repeatFrequency TEXT,
      nextDueDate TEXT,
      subtasks TEXT  -- Ensure subtasks column is created as TEXT
    )
    ''');
  }

  // On upgrade, ensure the subtasks column is added if the table is already created
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      ALTER TABLE tasks ADD COLUMN subtasks TEXT
      ''');
    }
  }

  // Insert task, encoding subtasks as JSON if available
  Future<int> insertTask(Map<String, dynamic> task) async {
    try {
      final db = await instance.database;



      // Ensure other properties are handled correctly before inserting into DB
      if (task['repeatFrequency'] == null) {
        task['repeatFrequency'] = '';
      }

      if (task['nextDueDate'] == null) {
        task['nextDueDate'] = '';
      }

      // Insert the task into the database and capture the inserted row ID
      int id = await db.insert('tasks', task);
      return id; // Return the task ID
    } catch (e) {
      print("Error inserting task: $e");
      throw Exception("Failed to add task: $e");
    }
  }


  // Get all tasks from the database
  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await instance.database;
    return await db.query('tasks');
  }

  // Fetch task by ID
  Future<Map<String, dynamic>?> getTaskById(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Update a task with subtasks and calculate next due date if needed
  Future<void> updateTask(int id, Map<String, dynamic> task) async {
    final db = await instance.database;

    // If the task is completed, handle next occurrence logic
    if (task['isCompleted'] == 1) {
      String? frequency = task['repeatFrequency'];
      if (frequency != null && frequency.isNotEmpty) {
        // Calculate the next occurrence date based on frequency
        DateTime currentDate = DateTime.parse(task['nextDueDate'] ?? DateTime.now().toIso8601String());
        DateTime nextDate;

        switch (frequency) {
          case "daily":
            nextDate = currentDate.add(Duration(minutes: 5));
            break;
          case "weekly":
            nextDate = currentDate.add(Duration(days: 7));
            break;
          case "monthly":
            nextDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
            break;
          default:
            nextDate = currentDate;
            break;
        }

        // Update task with the new nextDueDate
        task['nextDueDate'] = nextDate.toIso8601String();
      }
    }

    await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  // Delete a task from the database
  Future<void> deleteTask(int id) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Get only completed tasks
  Future<List<Map<String, dynamic>>> getCompletedTasks() async {
    final db = await instance.database;
    return await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
  }
}
