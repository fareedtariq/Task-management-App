import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'task.dart';
import 'notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime? _dueDate;
  String _repeatFrequency = 'None';

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final dueDate = _dueDate ?? DateTime.now();
      Task newTask = Task(
        title: _title,
        description: _description,
        dueDate: _dueDate!,
        repeatFrequency: _repeatFrequency,
        nextDueDate: _dueDate,
      );

      int taskId = await DatabaseHelper.instance.insertTask(newTask.toMap());

      // Schedule initial notification
      if (_dueDate != null) {
        NotificationService.scheduleDueDateReminder(_dueDate!, _title);
        _scheduleRecurringNotifications(taskId,_title,dueDate,_repeatFrequency
        );
      }

      Navigator.pop(context);
    }
  }
  Future<void> _scheduleRecurringNotifications(int taskId,String title, DateTime dueDate, String repeatFrequency) async {
    DateTime nextReminder = dueDate;

    // Set the next reminder time based on frequency
    switch (repeatFrequency.toLowerCase()) {
      case 'daily':
        nextReminder = nextReminder.add(Duration(minutes: 5));
        break;
      case 'weekly':
        nextReminder = nextReminder.add(Duration(days: 7));
        break;
      case 'monthly':
        nextReminder = DateTime(nextReminder.year, nextReminder.month + 1, nextReminder.day);
        break;
      default:
        return; // No action if frequency is invalid
    }

    // Schedule the next notification using a notification service
    NotificationService.scheduleDueDateReminder(nextReminder, title);

    // Update `nextDueDate` in the database with the calculated date
    await DatabaseHelper.instance.updateTask(taskId, {
      'id': taskId,
      'nextDueDate': nextReminder.toIso8601String(),
    });
  }


  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (value) => _title = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Due Date & Time',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  ),
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: _dueDate != null ? _dueDate!.toLocal().toString().split(' ')[0] : '',
                ),
                validator: (value) => _dueDate == null ? 'Select a due date' : null,
              ),
              DropdownButtonFormField<String>(
                value: _repeatFrequency,
                decoration: InputDecoration(labelText: 'Repeat Frequency'),
                items: ['None', 'Daily', 'Weekly', 'Monthly']
                    .map((String frequency) {
                  return DropdownMenuItem<String>(
                    value: frequency,
                    child: Text(frequency),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _repeatFrequency = newValue ?? 'None';
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
