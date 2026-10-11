import 'package:cloud_firestore/cloud_firestore.dart';

enum Priority { low, medium, high }

class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TodoModel {
  final String taskId;
  final String userId;
  final String title;
  final String description;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int colorIndex;
  final List<ChecklistItem> checklist;

  /// Optional deadline (older documents have none).
  final DateTime? dueDate;

  /// Pinned tasks float to the top of the deck.
  final bool pinned;

  TodoModel({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.isCompleted = false,
    required this.colorIndex,
    this.checklist = const [],
    this.dueDate,
    this.pinned = false,
  });

  // Convert TodoModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'isCompleted': isCompleted,
      'colorIndex': colorIndex,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'pinned': pinned,
    };
  }

  // Create TodoModel from Firestore Map
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    try {
      List<ChecklistItem> checklistItems = [];
      if (map['checklist'] != null) {
        checklistItems = (map['checklist'] as List)
            .map((item) => ChecklistItem.fromMap(item as Map<String, dynamic>))
            .toList();
      }

      return TodoModel(
        taskId: map['taskId'] ?? '',
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        priority: _parsePriority(map['priority']),
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: map['updatedAt'] != null
            ? _parseTimestamp(map['updatedAt'])
            : null,
        completedAt: map['completedAt'] != null
            ? _parseTimestamp(map['completedAt'])
            : null,
        isCompleted: map['isCompleted'] ?? false,
        colorIndex: map['colorIndex'] is int ? map['colorIndex'] : 0,
        checklist: checklistItems,
        dueDate: map['dueDate'] != null
            ? _parseTimestamp(map['dueDate'])
            : null,
        pinned: map['pinned'] == true,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to parse priority
  static Priority _parsePriority(dynamic priority) {
    if (priority is String) {
      return Priority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => Priority.medium,
      );
    } else if (priority is int) {
      return priority >= 0 && priority < Priority.values.length
          ? Priority.values[priority]
          : Priority.medium;
    }
    return Priority.medium;
  }

  // Helper method to parse Timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  // Check if all checklist items are completed
  bool get areAllChecklistItemsCompleted {
    if (checklist.isEmpty) return false;
    return checklist.every((item) => item.isCompleted);
  }

  // Get checklist completion percentage
  double get checklistCompletionPercentage {
    if (checklist.isEmpty) return 0.0;
    final completed = checklist.where((item) => item.isCompleted).length;
    return completed / checklist.length;
  }

  // Copy with method
  TodoModel copyWith({
    String? taskId,
    String? userId,
    String? title,
    String? description,
    Priority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? isCompleted,
    int? colorIndex,
    List<ChecklistItem>? checklist,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? pinned,
  }) {
    return TodoModel(
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      colorIndex: colorIndex ?? this.colorIndex,
      checklist: checklist ?? this.checklist,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      pinned: pinned ?? this.pinned,
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Past its due day and still open.
  bool isOverdue(DateTime now) =>
      !isCompleted && dueDate != null && _day(dueDate!).isBefore(_day(now));

  bool isDueToday(DateTime now) =>
      !isCompleted && dueDate != null && _day(dueDate!) == _day(now);

  /// Whole days from today to the due date (negative when overdue).
  int? daysUntilDue(DateTime now) =>
      dueDate == null ? null : _day(dueDate!).difference(_day(now)).inDays;
}