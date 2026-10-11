import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTodoService service;

  setUp(() {
    service = FakeTodoService([
      sampleTodo(id: 'T1', title: 'Alpha', priority: Priority.low),
      sampleTodo(id: 'T2', title: 'Bravo', priority: Priority.high),
      sampleTodo(id: 'T3', title: 'Done one', completed: true),
      sampleTodo(id: 'X9', userId: 'someone-else', title: 'Not mine'),
    ]);
  });

  test('only my open and completed tasks are loaded', () async {
    final p = newTodos(service);
    p.listenToTodos('USER000001');
    p.listenToCompletedTodos('USER000001');
    await settle();
    expect(p.todos.map((t) => t.taskId).toSet(), {'T1', 'T2'});
    expect(p.completedTodos.map((t) => t.taskId), ['T3']);
    expect(p.stats.completed, 1);
    p.dispose();
  });

  test('search and filters change visibleTodos but not todos', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    p.setQuery(const TodoQuery(text: 'bra'));
    expect(p.visibleTodos.map((t) => t.taskId), ['T2']);
    expect(p.todos.length, 2);
    p.setQuery(const TodoQuery(priority: Priority.low));
    expect(p.visibleTodos.map((t) => t.taskId), ['T1']);
    p.clearFilters();
    expect(p.visibleTodos.length, 2);
    p.dispose();
  });

  test('clearFilters keeps the chosen sort', () async {
    final p = newTodos(service);
    p.setQuery(const TodoQuery(text: 'x', sort: TodoSort.title));
    p.clearFilters();
    expect(p.query.sort, TodoSort.title);
    expect(p.query.text, '');
    p.dispose();
  });

  test('create adds a task with due date and pin', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    final ok = await p.createTodo(
      userId: 'USER000001',
      title: 'New',
      description: 'desc',
      priority: Priority.high,
      dueDate: DateTime(2026, 10, 20),
      pinned: true,
    );
    await settle();
    expect(ok, isTrue);
    final created = p.todos.firstWhere((t) => t.title == 'New');
    expect(created.pinned, isTrue);
    expect(created.dueDate, DateTime(2026, 10, 20));
    expect(p.visibleTodos.first.title, 'New'); // pinned first
    p.dispose();
  });

  test('complete then undo (mark incomplete) moves it back and forth', () async {
    final p = newTodos(service);
    p.listenToTodos('USER000001');
    p.listenToCompletedTodos('USER000001');
    await settle();
    await p.completeTodo('T1');
    await settle();
    expect(p.todos.map((t) => t.taskId), ['T2']);
    expect(p.completedTodos.map((t) => t.taskId).toSet(), {'T1', 'T3'});
    await p.markAsIncomplete('T1');
    await settle();
    expect(p.todos.map((t) => t.taskId).toSet(), {'T1', 'T2'});
    p.dispose();
  });

  test('delete then restore brings the task back unchanged', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    final original = p.todos.firstWhere((t) => t.taskId == 'T2');
    await p.deleteTodo('T2');
    await settle();
    expect(p.todos.map((t) => t.taskId), ['T1']);
    await p.restoreTodo(original);
    await settle();
    final back = p.todos.firstWhere((t) => t.taskId == 'T2');
    expect(back.title, 'Bravo');
    expect(back.priority, Priority.high);
    p.dispose();
  });

  test('togglePinned flips the flag', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    await p.togglePinned(p.todos.firstWhere((t) => t.taskId == 'T1'));
    await settle();
    expect(p.todos.firstWhere((t) => t.taskId == 'T1').pinned, isTrue);
    expect(p.visibleTodos.first.taskId, 'T1');
    p.dispose();
  });

  test('a failing write returns false and sets actionError only', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    service.failWith = 'offline';
    final ok = await p.deleteTodo('T1');
    expect(ok, isFalse);
    expect(p.actionError, contains('offline'));
    expect(p.error, isNull);
    expect(p.isLoading, isFalse);
    p.dispose();
  });

  test('reset forgets tasks and filters', () async {
    final p = newTodos(service)..listenToTodos('USER000001');
    await settle();
    p.setQuery(const TodoQuery(text: 'a'));
    p.reset();
    expect(p.todos, isEmpty);
    expect(p.query.isFiltering, isFalse);
    p.dispose();
  });

  group('AuthProvider with a fake service', () {
    test('picks up the signed-in user', () async {
      final auth = signedInAuth();
      await auth.checkInitialAuthState();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user!.name, 'Aarav Mehta');
      auth.dispose();
    });

    test('sign in succeeds / fails with a message', () async {
      final fake = FakeAuthService()..accounts['a@b.co'] = 'secret1';
      final auth = AuthProvider(service: fake);
      expect(await auth.signIn(email: 'a@b.co', password: 'nope'), isFalse);
      expect(auth.errorMessage, 'Wrong password provided.');
      expect(await auth.signIn(email: 'a@b.co', password: 'secret1'), isTrue);
      expect(auth.isAuthenticated, isTrue);
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      auth.dispose();
    });
  });
}
