import 'package:flutter/material.dart';
import 'package:task_manager_app/database_helper.dart';
import 'package:task_manager_app/task.dart';
import 'dart:async'; // Import for Timer

class RepeatedTaskScreen extends StatefulWidget {
  @override
  _RepeatedTaskScreenState createState() => _RepeatedTaskScreenState();
}

class _RepeatedTaskScreenState extends State<RepeatedTaskScreen> {
  List<Task> repeatedTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchRepeatedTasks();

    // Trigger an update every 24 hours (86400 seconds)
    Timer.periodic(Duration(seconds: 86400), (timer) {
      _fetchRepeatedTasks();

    });
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final dbHelper = DatabaseHelper.instance;

    // If the task is not completed, update the due date based on frequency
    if (task.isCompleted) {
      DateTime newDueDate = task.dueDate;  // Start with the original dueDate
print("completion called");
      if (task.repeatFrequency == 'Daily') {
        newDueDate = newDueDate.add(Duration(days: 1)); // Update due date by 1 day
      } else if (task.repeatFrequency == 'Weekly') {
        newDueDate = newDueDate.add(Duration(days: 7)); // Update due date by 7 days (1 week)
      } else if (task.repeatFrequency == 'Monthly') {
        newDueDate = DateTime(
          newDueDate.year,
          newDueDate.month + 1,
          newDueDate.day,
        );
      }

      // Create a new Task with the updated dueDate and set isCompleted to false
      Task updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: newDueDate,  // Set the new due date
        isCompleted: false,   // Set to false so it's not marked as completed
        repeatFrequency: task.repeatFrequency,
        nextDueDate: task.nextDueDate,
      );

      // Update the task in the database with the new due date and reset completion
      await dbHelper.updateTask(task.id!, updatedTask.toMap());

      // Fetch updated tasks
      _fetchRepeatedTasks();
    } else {
      // If task is already completed, reset completion and move to end of list
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,  // Keep the original due date
        isCompleted: false,     // Reset to false
        repeatFrequency: task.repeatFrequency,
        nextDueDate: task.nextDueDate,
      );

      await dbHelper.updateTask(task.id!, updatedTask.toMap());

      // Move the task to the end of the list after completing it
      _fetchRepeatedTasks();
    }
  }

  Future<void> _fetchRepeatedTasks() async {
    final tasks = await DatabaseHelper.instance.getTasks();

    if (mounted) {
      setState(() {
        repeatedTasks = tasks
            .map((taskMap) => Task.fromMap(taskMap))
            .where((task) => task.repeatFrequency != null && task.repeatFrequency != 'None')
            .toList();

        // Sort tasks, moving completed tasks to the end
        repeatedTasks.sort((a, b) {
          if (a.isCompleted == b.isCompleted) {
            return 0;
          } else if (a.isCompleted) {
            return 1;
          } else {
            return -1;
          }
        });

        // Update due date for repeated tasks based on their frequency
        for (var task in repeatedTasks) {
          if (!task.isCompleted) {
            DateTime newDueDate = task.dueDate;  // Start with the original dueDate

            if (task.repeatFrequency == 'Daily') {
              newDueDate = newDueDate.add(Duration(seconds
                  : 10));
              print(newDueDate);// Update due date by 1 day
            } else if (task.repeatFrequency == 'Weekly') {
              newDueDate = newDueDate.add(Duration(days: 7)); // Update due date by 7 days (1 week)
            } else if (task.repeatFrequency == 'Monthly') {
              newDueDate = DateTime(
                newDueDate.year,
                newDueDate.month + 1,
                newDueDate.day,
              );
            }

            // Update the task in the database with the new due date and reset completion
            Task updatedTask = Task(
              id: task.id,
              title: task.title,
              description: task.description,
              dueDate: newDueDate,  // Set the new due date
              isCompleted: false,
              repeatFrequency: task.repeatFrequency,
              nextDueDate: task.nextDueDate,
            );

            DatabaseHelper.instance.updateTask(task.id!, updatedTask.toMap());
          }
        }
      });
    }
  }



  // Edit task dialog
  Future<void> _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    bool isCompleted = task.isCompleted;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    CheckboxListTile(
                      title: Text('Completed'),
                      value: isCompleted,
                      onChanged: (value) {
                        setDialogState(() {
                          isCompleted = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Update the task in the database
                    final updatedTask = Task(
                      id: task.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: task.dueDate, // Keep the original due date if not editing
                      isCompleted: isCompleted,
                      repeatFrequency: task.repeatFrequency,
                    );

                    await DatabaseHelper.instance.updateTask(task.id!, updatedTask.toMap());
                    _fetchRepeatedTasks(); // Refresh the task list
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Repeated Tasks'),
      ),
      body: repeatedTasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/1.png', // Placeholder image path
              height: 200, // Adjust height as needed
              width: 200, // Adjust width as needed
              fit: BoxFit.contain,
            ),
            SizedBox(height: 16),
            Text(
              'No repeated tasks available',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: repeatedTasks.length,
        itemBuilder: (context, index) {
          final task = repeatedTasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description),
                  Text('Due: ${task.dueDate.toLocal()}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min, // To fit icons closely together
                children: [
                  IconButton(
                    icon: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleTaskCompletion(task), // Toggle completion status
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteTask(task.id!); // Delete task
                      _fetchRepeatedTasks(); // Refresh the task list
                    },
                  ),
                ],
              ),
              onTap: () => _showEditTaskDialog(task), // Open edit dialog
            ),
          );
        },
      ),
    );
  }
}
