//
//
// class Task {
//   final int? id;
//   final String title;
//   final String description;
//   final DateTime dueDate;
//   final bool isCompleted;
//   final String? repeatFrequency; // New property to specify repeat frequency
//   final String? nextDueDate; // New property for the next due date
//   // List<Map<String, dynamic>>? subtasks; // List of subtasks
//
//   Task({
//     this.id,
//     required this.title,
//     required this.description,
//     required this.dueDate,
//     this.isCompleted = false,
//     this.repeatFrequency, // Initialize the repeat frequency
//     this.nextDueDate,
//     // this.subtasks,
//   });
//
//   // Convert Task to Map<String, dynamic> for storage in database
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'dueDate': dueDate,
//       'isCompleted': isCompleted ? 1 : 0,
//       'repeatFrequency': repeatFrequency, // Add repeatFrequency to map
//       'nextDueDate': nextDueDate,
//       // 'subtasks': subtasks != null ? jsonEncode(subtasks) : null, // Ensure null if no subtasks
//     };
//   }
//
//   // Convert Map<String, dynamic> from database to Task object
//   static Task fromMap(Map<String, dynamic> map) {
//     return Task(
//       id: map['id'], // id can be null, so it's okay
//       title: map['title'] ?? 'Untitled Task', // Default title if null
//       description: map['description'] ?? 'No description provided', // Default description if null
//       dueDate: map['dueDate'] ?? 'No due date', // Default due date if null
//       isCompleted: map['isCompleted'] == 1,
//       repeatFrequency: map['repeatFrequency'], // Extract repeatFrequency from map
//       nextDueDate: map['nextDueDate'],
//       // subtasks: map['subtasks'] != null
//       //     ? (map['subtasks'] is String
//       //     ? List<Map<String, dynamic>>.from(jsonDecode(map['subtasks']))
//       //     : List<Map<String, dynamic>>.from(map['subtasks']))
//       //     : [], // Empty list if no subtasks
//     );
//   }
// }
class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;  // Change from String to DateTime
  final bool isCompleted;
  final String? repeatFrequency;
  final DateTime? nextDueDate; // Change to DateTime

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.repeatFrequency,
    this.nextDueDate,
  });

  // Convert Task to Map<String, dynamic> for storage in database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),  // Convert DateTime to String
      'isCompleted': isCompleted ? 1 : 0,
      'repeatFrequency': repeatFrequency,
      'nextDueDate': nextDueDate?.toIso8601String(), // Convert DateTime to String
    };
  }

  // Convert Map<String, dynamic> from database to Task object
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'] ?? 'Untitled Task',
      description: map['description'] ?? 'No description provided',
      dueDate: DateTime.parse(map['dueDate'] ?? 'No due date'),  // Convert String back to DateTime
      isCompleted: map['isCompleted'] == 1,
      repeatFrequency: map['repeatFrequency'],
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,  // Convert String to DateTime
    );
  }
}
