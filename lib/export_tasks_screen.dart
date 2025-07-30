import 'package:flutter/material.dart';
import 'task.dart';
import 'export_functions.dart'; // Ensure export functions are defined here
import 'package:share_plus/share_plus.dart';

class ExportTasksScreen extends StatelessWidget {
  final List<Task> tasks; // Assume Task is a model class for tasks

  ExportTasksScreen({required this.tasks});

  // Function to share file
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles(
          [XFile(filePath)], // The exported file path
          text: 'Here is your exported file'
      );
      print('File shared successfully');
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Tasks'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Export as CSV Button
                  ElevatedButton(
                    onPressed: () async {
                      String? csvFilePath = await exportTasksToCSV(tasks); // Get CSV file path
                      if (csvFilePath != null) {
                        shareFile(csvFilePath); // Share the file after export
                      }
                    },
                    child: Text('Export as CSV'),
                  ),
                  SizedBox(width: 16), // Spacing between buttons
                  // Export as PDF Button
                  ElevatedButton(
                    onPressed: () async {
                      String? pdfFilePath = await exportTasksToPDF(tasks); // Get PDF file path
                      if (pdfFilePath != null) {
                        shareFile(pdfFilePath); // Share the file after export
                      }
                    },
                    child: Text('Export as PDF'),
                  ),
                ],
              ),
            ),
            // Display task data in a table
            DataTable(
              columns: [
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Due Date')),
                DataColumn(label: Text('Completed')),
                DataColumn(label: Text('Frequency')),
              ],
              rows: tasks.map((task) {
                return DataRow(cells: [
                  DataCell(Text(task.title)),
                  DataCell(Text(task.description)),
                  DataCell(Text(task.dueDate.toString())),
                  DataCell(Text(task.isCompleted ? 'Yes' : 'No')),
                  DataCell(Text(task.repeatFrequency ?? 'No frequency specified')),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
