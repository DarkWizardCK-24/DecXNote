import 'dart:async';

import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/services/todo_service.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter/foundation.dart';

class TodoProvider with ChangeNotifier {
  TodoProvider({TodoService? service, DateTime Function()? clock})
    : _service = service ?? FirestoreTodoService(),
      _clock = clock ?? DateTime.now;

  final TodoService _service;
  final DateTime Function() _clock;

  List<TodoModel> _todos = [];
  List<TodoModel> _completedTodos = [];
  bool _isLoading = false;
  String? _error;
  String? _actionError;
  TodoQuery _query = const TodoQuery();

  StreamSubscription<List<TodoModel>>? _todoSub;
  StreamSubscription<List<TodoModel>>? _completedSub;

  /// All open tasks, unfiltered.
  List<TodoModel> get todos => _todos;
  List<TodoModel> get completedTodos => _completedTodos;
  bool get isLoading => _isLoading;
  /// Problem loading the task streams.
  String? get error => _error;

  /// Problem with the last create / update / delete.
  String? get actionError => _actionError;
  DateTime get now => _clock();

  TodoQuery get query => _query;

  /// Open tasks after search / filter / sort (what the deck and grid show).
  List<TodoModel> get visibleTodos => applyQuery(_todos, _query, _clock());

  TodoStats get stats => TodoStats.from(_todos, _completedTodos, _clock());

  void setQuery(TodoQuery query) {
    if (query == _query) return;
    _query = query;
    notifyListeners();
  }

  void clearFilters() => setQuery(TodoQuery(sort: _query.sort));

  void listenToTodos(String userId) {
    _todoSub?.cancel();
    _todoSub = _service
        .getTodosStream(userId)
        .listen(
          (todos) {
            _todos = todos;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  void listenToCompletedTodos(String userId) {
    _completedSub?.cancel();
    _completedSub = _service
        .getCompletedTodosStream(userId)
        .listen(
          (todos) {
            _completedTodos = todos;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  /// Stops listening and forgets everything (used on sign out).
  void reset() {
    _todoSub?.cancel();
    _completedSub?.cancel();
    _todoSub = null;
    _completedSub = null;
    _todos = [];
    _completedTodos = [];
    _query = const TodoQuery();
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      _isLoading = true;
      _actionError = null;
      notifyListeners();
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTodo({
    required String userId,
    required String title,
    required String description,
    required Priority priority,
    List<ChecklistItem>? checklist,
    DateTime? dueDate,
    bool pinned = false,
  }) => _run(
    () => _service.createTodo(
      userId: userId,
      title: title,
      description: description,
      priority: priority,
      checklist: checklist,
      dueDate: dueDate,
      pinned: pinned,
    ),
  );

  Future<bool> updateTodo(TodoModel todo) =>
      _run(() => _service.updateTodo(todo));

  Future<bool> togglePinned(TodoModel todo) =>
      _run(() => _service.updateTodo(todo.copyWith(pinned: !todo.pinned)));

  Future<bool> updateChecklistItems(
    String taskId,
    List<ChecklistItem> checklist,
  ) async {
    try {
      await _service.updateChecklistItem(taskId, checklist);
      return true;
    } catch (e) {
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTodo(String taskId) =>
      _run(() => _service.completeTodo(taskId));

  Future<bool> markAsIncomplete(String taskId) =>
      _run(() => _service.markAsIncomplete(taskId));

  Future<bool> deleteTodo(String taskId) =>
      _run(() => _service.deleteTodo(taskId));

  /// Brings a deleted task back exactly as it was ("Undo").
  Future<bool> restoreTodo(TodoModel todo) =>
      _run(() => _service.restoreTodo(todo));

  void clearError() {
    _error = null;
    _actionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _todoSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }
}
