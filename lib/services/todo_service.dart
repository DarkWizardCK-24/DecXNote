import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deck_note/models/todo_model.dart';

/// What the app needs from a task store. The real one is Firestore; tests and
/// screenshots use an in-memory fake.
abstract class TodoService {
  Future<TodoModel> createTodo({
    required String userId,
    required String title,
    required String description,
    required Priority priority,
    List<ChecklistItem>? checklist,
    DateTime? dueDate,
    bool pinned = false,
  });

  Stream<List<TodoModel>> getTodosStream(String userId);
  Stream<List<TodoModel>> getCompletedTodosStream(String userId);
  Future<void> updateTodo(TodoModel todo);
  Future<void> updateChecklistItem(String taskId, List<ChecklistItem> checklist);
  Future<void> completeTodo(String taskId);
  Future<void> markAsIncomplete(String taskId);
  Future<void> deleteTodo(String taskId);

  /// Writes a todo back under its original id (used by "Undo" after delete).
  Future<void> restoreTodo(TodoModel todo);
}

class FirestoreTodoService implements TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _generateTaskId() async {
    final counterDoc = _firestore.collection('counters').doc('taskId');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterDoc);

      int newCount = 1;
      if (snapshot.exists) {
        newCount = (snapshot.data()?['count'] ?? 0) + 1;
      }

      transaction.set(counterDoc, {'count': newCount}, SetOptions(merge: true));

      return 'TASK${newCount.toString().padLeft(6, '0')}';
    });
  }

  @override
  Future<TodoModel> createTodo({
    required String userId,
    required String title,
    required String description,
    required Priority priority,
    List<ChecklistItem>? checklist,
    DateTime? dueDate,
    bool pinned = false,
  }) async {
    try {
      final taskId = await _generateTaskId();

      final random = Random();
      final colorIndex = random.nextInt(10);

      final todo = TodoModel(
        taskId: taskId,
        userId: userId,
        title: title,
        description: description,
        priority: priority,
        createdAt: DateTime.now(),
        colorIndex: colorIndex,
        checklist: checklist ?? [],
        dueDate: dueDate,
        pinned: pinned,
      );

      final todoMap = todo.toMap();

      await _firestore.collection('todos').doc(taskId).set(todoMap);

      return todo;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<TodoModel>> getTodosStream(String userId) {
    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final todos = <TodoModel>[];

          for (var doc in snapshot.docs) {
            try {
              final todo = TodoModel.fromMap(doc.data());
              todos.add(todo);
            } catch (_) {
              // Skip documents that cannot be parsed.
            }
          }

          // Sort by updatedAt (for restored tasks) or createdAt, newest first
          todos.sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt;
            final bDate = b.updatedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });

          return todos;
        });
  }

  @override
  Stream<List<TodoModel>> getCompletedTodosStream(String userId) {
    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final todos = <TodoModel>[];

          for (var doc in snapshot.docs) {
            try {
              final todo = TodoModel.fromMap(doc.data());
              todos.add(todo);
            } catch (_) {
              // Skip documents that cannot be parsed.
            }
          }

          // Sort by completedAt, newest first
          todos.sort((a, b) {
            final aDate = a.completedAt ?? a.updatedAt ?? a.createdAt;
            final bDate = b.completedAt ?? b.updatedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });

          return todos;
        });
  }

  @override
  Future<void> updateTodo(TodoModel todo) async {
    try {
      final updatedTodo = todo.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('todos')
          .doc(todo.taskId)
          .update(updatedTodo.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateChecklistItem(String taskId, List<ChecklistItem> checklist) async {
    try {
      await _firestore.collection('todos').doc(taskId).update({
        'checklist': checklist.map((item) => item.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> completeTodo(String taskId) async {
    try {
      await _firestore.collection('todos').doc(taskId).update({
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsIncomplete(String taskId) async {
    try {
      await _firestore.collection('todos').doc(taskId).update({
        'isCompleted': false,
        'completedAt': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTodo(String taskId) async {
    try {
      await _firestore.collection('todos').doc(taskId).delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> restoreTodo(TodoModel todo) async {
    await _firestore.collection('todos').doc(todo.taskId).set(todo.toMap());
  }
}
