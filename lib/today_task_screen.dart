import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'task.dart';

class TodayTaskScreen extends StatefulWidget {
  @override
  _TodayTaskScreenState createState() => _TodayTaskScreenState();
}



class _TodayTaskScreenState extends State<TodayTaskScreen> {
  List<Task> todayTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayTasks(); // Fetch today's tasks when the screen is loaded
  }

  // Fetch tasks from database where dueDate is today's date
  Future<void> _fetchTodayTasks() async {
    final dbHelper = DatabaseHelper.instance;
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    List<Map<String, dynamic>> taskMaps = await dbHelper.getTasks();

    setState(() {
      todayTasks = taskMaps
          .map((taskMap) => Task.fromMap(taskMap))
          .where((task) {
        String taskDueDate = DateFormat('yyyy-MM-dd').format(task.dueDate!); // assuming dueDate is DateTime
        return taskDueDate == todayDate && !task.isCompleted;
      })
          .toList();
    });
  }

  // Update task completion status
  // Update task completion status and handle frequency for next occurrence
  Future<void> _toggleTaskCompletion(Task task) async {
    final dbHelper = DatabaseHelper.instance;

    // Toggle the completion status
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isCompleted: !task.isCompleted, // Toggle the completion status
      repeatFrequency: task.repeatFrequency,
      nextDueDate: task.nextDueDate, // Keeping track of next due date
    );

    // If task is completed, apply repeat frequency to calculate next due date
    if (updatedTask.isCompleted) {
      DateTime currentDate = DateTime.parse(updatedTask.dueDate!);
      DateTime nextDueDate;

      // Apply frequency to calculate the next due date
      switch (updatedTask.repeatFrequency) {
        case "daily":
          nextDueDate = currentDate.add(Duration(days: 1));
          break;
        case "weekly":
          nextDueDate = currentDate.add(Duration(days: 7));
          break;
        case "monthly":
          nextDueDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        default:
          nextDueDate = currentDate; // Default to current if no valid frequency
          break;
      }

      // Update the next due date for recurring tasks
      updatedTask.DueDate = nextDueDate.toIso8601String();
    }

    // Update the task in the database with the new completion status and next due date
    await dbHelper.updateTask(task.id!, updatedTask.toMap());

    // Refresh the task list to reflect the update
    _fetchTodayTasks(); // Re-fetch tasks to refresh the screen
  }


  // Show dialog to edit task details
  Future<void> _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final nextDueDateController = TextEditingController(text: task.nextDueDate.toString());
    bool isCompleted = task.isCompleted;
    String? selectedFrequency = task.repeatFrequency;

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
                    DropdownButton<String>(
                      value: selectedFrequency,
                      hint: Text('Select Repeat Frequency'),
                      items: <String>['None', 'Daily', 'Weekly', 'Monthly'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedFrequency = newValue;
                        });
                      },
                    ),
                    TextField(
                      controller: nextDueDateController,
                      decoration: InputDecoration(labelText: 'Next Due Date'),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            nextDueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
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
                    final updatedTask = Task(
                      id: task.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: task.dueDate,
                      isCompleted: isCompleted,
                      repeatFrequency: selectedFrequency,

                    );

                    await DatabaseHelper.instance.updateTask(task.id!, updatedTask.toMap());
                    _fetchTodayTasks(); // Refresh the task list after updating
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
        title: Text('Today\'s Tasks'),
      ),
      body: todayTasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/12.png', width: 200), // Display the image when no tasks are present
            SizedBox(height: 16),
            Text(
              'No tasks for today!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: todayTasks.length,
        itemBuilder: (context, index) {
          final task = todayTasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description),
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

