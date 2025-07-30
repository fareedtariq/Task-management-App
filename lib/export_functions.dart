import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'task.dart'; // Import your Task model

// Function to export tasks to CSV
Future<String> exportTasksToCSV(List<Task> tasks) async {
  List<List<dynamic>> rows = [];
  rows.add(['Title', 'Due Date', 'Status', 'Repeat Frequency']);

  for (var task in tasks) {
    rows.add([task.title, task.dueDate, task.isCompleted ? 'Completed' : 'Pending', task.repeatFrequency ?? 'No frequency specified']);
  }

  String csv = const ListToCsvConverter().convert(rows);

  // Get the temporary directory
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/tasks.csv';

  File file = File(filePath);
  await file.writeAsString(csv);

  print('CSV file saved at $filePath');
  return filePath;  // Return the file path for sharing
}

// Function to export tasks to PDF
Future<String> exportTasksToPDF(List<Task> tasks) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Tasks', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              data: <List<String>>[
                <String>['Title', 'Due Date', 'Status', 'Repeat Frequency'],
                ...tasks.map((task) => [
                  task.title,
                  task.dueDate.toString(),  // Ensure the due date is in string format
                  task.isCompleted ? 'Completed' : 'Pending',
                  task.repeatFrequency ?? 'No frequency specified',
                ]),
              ],
            ),
          ],
        );
      },
    ),
  );

  // Get the temporary directory
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/tasks.pdf';

  File file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  print('PDF file saved at $filePath');
  return filePath;  // Return the file path for sharing
}

// Function to share the exported file
Future<void> shareExportedFile(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Here is your exported file',
    );
  } else {
    print('File not found');
  }
}

// Function to export and share tasks in the chosen format
Future<void> exportAndShareTasks(List<Task> tasks, {String format = 'csv'}) async {
  String filePath = '';

  if (format == 'csv') {
    filePath = await exportTasksToCSV(tasks);
  } else if (format == 'pdf') {
    filePath = await exportTasksToPDF(tasks);
  } else {
    print("Unsupported format: $format");
    return;
  }

  await shareExportedFile(filePath);  // Share the exported file
}
