import 'dart:async';

import 'package:deck_note/main.dart';
import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/models/user_model.dart';
import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/services/auth_service.dart';
import 'package:deck_note/services/todo_service.dart';
import 'package:flutter/widgets.dart';

/// "Now" for every test, so due dates are deterministic.
final DateTime testNow = DateTime(2026, 10, 13, 15, 40);

/// In-memory [AuthService] with a tiny account database.
class FakeAuthService implements AuthService {
  FakeAuthService({UserModel? signedIn}) : _user = signedIn;

  /// email -> password
  final Map<String, String> accounts = {};
  UserModel? _user;
  final _changes = StreamController<String?>.broadcast();
  bool signedOut = false;

  @override
  Stream<String?> get authStateChanges async* {
    yield _user?.userId;
    yield* _changes.stream;
  }

  @override
  Future<UserModel?> getUserData() async => _user;

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    if (accounts[email] != password) {
      throw 'Wrong password provided.';
    }
    _user = UserModel(
      userId: 'USER000001',
      name: 'Test User',
      email: email,
      createdAt: DateTime(2026, 3, 2),
    );
    return _user;
  }

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (accounts.containsKey(email)) {
      throw 'An account already exists for that email.';
    }
    accounts[email] = password;
    _user = UserModel(
      userId: 'USER000002',
      name: name,
      email: email,
      createdAt: DateTime(2026, 10, 13),
    );
    return _user;
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    _user = _user?.copyWith(name: name, email: email);
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _user = null;
    _changes.add(null);
  }
}

/// In-memory [TodoService]; streams update whenever something changes.
class FakeTodoService implements TodoService {
  FakeTodoService([List<TodoModel> seed = const []]) {
    for (final t in seed) {
      _store[t.taskId] = t;
    }
  }

  final Map<String, TodoModel> _store = {};
  final _changes = StreamController<void>.broadcast();
  int _next = 100;

  /// When set, the next write throws it.
  Object? failWith;

  List<TodoModel> get all => _store.values.toList();

  Stream<List<TodoModel>> _watch(String userId, bool completed) async* {
    List<TodoModel> mine() =>
        _store.values
            .where((t) => t.userId == userId && t.isCompleted == completed)
            .toList();
    yield mine();
    await for (final _ in _changes.stream) {
      yield mine();
    }
  }

  @override
  Stream<List<TodoModel>> getTodosStream(String userId) =>
      _watch(userId, false);

  @override
  Stream<List<TodoModel>> getCompletedTodosStream(String userId) =>
      _watch(userId, true);

  void _guard() {
    if (failWith != null) throw failWith!;
  }

  void _put(TodoModel t) {
    _store[t.taskId] = t;
    _changes.add(null);
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
    _guard();
    final id = 'TASK${(_next++).toString().padLeft(6, '0')}';
    final todo = TodoModel(
      taskId: id,
      userId: userId,
      title: title,
      description: description,
      priority: priority,
      createdAt: testNow,
      colorIndex: 0,
      checklist: checklist ?? [],
      dueDate: dueDate,
      pinned: pinned,
    );
    _put(todo);
    return todo;
  }

  @override
  Future<void> updateTodo(TodoModel todo) async {
    _guard();
    _put(todo.copyWith(updatedAt: testNow));
  }

  @override
  Future<void> updateChecklistItem(
    String taskId,
    List<ChecklistItem> checklist,
  ) async {
    _guard();
    _put(_store[taskId]!.copyWith(checklist: checklist));
  }

  @override
  Future<void> completeTodo(String taskId) async {
    _guard();
    _put(_store[taskId]!.copyWith(isCompleted: true, completedAt: testNow));
  }

  @override
  Future<void> markAsIncomplete(String taskId) async {
    _guard();
    final t = _store[taskId]!;
    _put(
      TodoModel(
        taskId: t.taskId,
        userId: t.userId,
        title: t.title,
        description: t.description,
        priority: t.priority,
        createdAt: t.createdAt,
        updatedAt: testNow,
        isCompleted: false,
        colorIndex: t.colorIndex,
        checklist: t.checklist,
        dueDate: t.dueDate,
        pinned: t.pinned,
      ),
    );
  }

  @override
  Future<void> deleteTodo(String taskId) async {
    _guard();
    _store.remove(taskId);
    _changes.add(null);
  }

  @override
  Future<void> restoreTodo(TodoModel todo) async {
    _guard();
    _put(todo);
  }
}

TodoModel sampleTodo({
  String id = 'TASK000001',
  String userId = 'USER000001',
  String title = 'Write the report',
  String description = 'Quarterly numbers for the team',
  Priority priority = Priority.medium,
  DateTime? createdAt,
  DateTime? dueDate,
  bool pinned = false,
  bool completed = false,
  DateTime? completedAt,
  int colorIndex = 0,
  List<ChecklistItem> checklist = const [],
}) => TodoModel(
  taskId: id,
  userId: userId,
  title: title,
  description: description,
  priority: priority,
  createdAt: createdAt ?? testNow.subtract(const Duration(days: 3)),
  dueDate: dueDate,
  pinned: pinned,
  isCompleted: completed,
  completedAt: completed ? (completedAt ?? testNow) : null,
  colorIndex: colorIndex,
  checklist: checklist,
);

final UserModel testUser = UserModel(
  userId: 'USER000001',
  name: 'Aarav Mehta',
  email: 'aarav@example.com',
  createdAt: DateTime(2026, 3, 2),
);

/// The whole app with fakes, starting on [home].
Widget testApp({
  required AuthProvider auth,
  required TodoProvider todos,
  Widget? home,
}) => MyApp(auth: auth, todos: todos, home: home);

AuthProvider signedInAuth([FakeAuthService? service]) =>
    AuthProvider(service: service ?? FakeAuthService(signedIn: testUser));

TodoProvider newTodos(FakeTodoService service) =>
    TodoProvider(service: service, clock: () => testNow);

AuthProvider signedInAuthFor(FakeAuthService service) =>
    AuthProvider(service: service);
