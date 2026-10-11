import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/completed_todos_screen.dart';
import 'package:deck_note/screens/home_screen.dart';
import 'package:deck_note/screens/login_screen.dart';
import 'package:deck_note/utils/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';

/// Lets zero-length timers from the animation package fire before teardown.
Future<void> settleTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void setSize(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<TodoModel> seed() => [
  sampleTodo(
    id: 'T1',
    title: 'Pay rent',
    priority: Priority.high,
    dueDate: testNow.subtract(const Duration(days: 2)),
    colorIndex: 0,
  ),
  sampleTodo(
    id: 'T2',
    title: 'Plan trip',
    dueDate: testNow.add(const Duration(days: 5)),
    colorIndex: 2,
  ),
  sampleTodo(id: 'T3', title: 'Buy milk', priority: Priority.low, colorIndex: 3),
  sampleTodo(id: 'T4', title: 'Filed taxes', completed: true, colorIndex: 4),
];

Future<(TodoProvider, FakeTodoService)> pumpApp(
  WidgetTester tester, {
  Widget home = const HomeScreen(),
  List<TodoModel>? todos,
}) async {
  final service = FakeTodoService(todos ?? seed());
  final todoProvider = newTodos(service);
  final auth = signedInAuth();
  await tester.pump();
  await tester.pump();
  await tester.pumpWidget(testApp(auth: auth, todos: todoProvider, home: home));
  // The listeners start after the first frame.
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return (todoProvider, service);
}

void main() {
  setUpAll(loadAppFonts);

  group('phone layout (unchanged structure)', () {
    testWidgets('shows the card deck and swipe hints, no rail', (tester) async {
      setSize(tester, 430, 932);
      await pumpApp(tester);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.textContaining('Swipe left'), findsOneWidget);
      expect(find.text('Hi, Aarav Mehta'), findsOneWidget);
      // Smart sort: the overdue task is on top of the deck.
      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.byKey(const Key('due-label')), findsWidgets);
    });

    testWidgets('narrow windows stay on the phone layout', (tester) async {
      setSize(tester, Breakpoints.wide - 1, 900);
      await pumpApp(tester);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('search narrows the deck and can be cleared', (tester) async {
      setSize(tester, 430, 932);
      final (provider, _) = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('toggle-filters')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
      await tester.pump();
      expect(find.text('No matching tasks'), findsOneWidget);
      expect(provider.visibleTodos, isEmpty);
      await tester.tap(find.text('Clear filters'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No matching tasks'), findsNothing);
      expect(provider.visibleTodos.length, 3);
      await settleTimers(tester);
    });

    testWidgets('jump to a specific note from the overview', (tester) async {
      setSize(tester, 430, 932);
      await pumpApp(tester);
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck-overview')));
      await tester.pumpAndSettle();
      expect(find.text('All notes (3)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('overview-item-T3')));
      await tester.pumpAndSettle();
      expect(find.text('All notes (3)'), findsNothing);
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('previous / next wrap around, nothing is unreachable', (
      tester,
    ) async {
      setSize(tester, 430, 932);
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('deck-prev')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck-next')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('empty state when there are no tasks', (tester) async {
      setSize(tester, 430, 932);
      await pumpApp(tester, todos: []);
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('add a task with a priority and pin', (tester) async {
      setSize(tester, 430, 932);
      final (provider, service) = await pumpApp(tester, todos: []);
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Call mum');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Sunday evening',
      );
      await tester.tap(find.byKey(const Key('priority-high')));
      await tester.tap(find.byKey(const Key('pin-switch')));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();
      expect(service.all.single.title, 'Call mum');
      expect(service.all.single.priority, Priority.high);
      expect(service.all.single.pinned, isTrue);
      expect(find.text('Task added successfully!'), findsOneWidget);
      expect(provider.todos.length, 1);
    });

    testWidgets('title is required', (tester) async {
      setSize(tester, 430, 932);
      final (_, service) = await pumpApp(tester, todos: []);
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pump();
      expect(find.text('Please enter a title'), findsOneWidget);
      expect(service.all, isEmpty);
    });

    testWidgets('completed screen shows progress and tasks', (tester) async {
      setSize(tester, 430, 932);
      final (provider, _) = await pumpApp(tester);
      provider.listenToCompletedTodos('USER000001');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byTooltip('Completed tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Completed Tasks'), findsOneWidget);
      expect(find.text('Filed taxes'), findsOneWidget);
      // 1 of 4 tasks done.
      expect(find.byKey(const Key('completion-percent')), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('1 of 4 tasks done'), findsOneWidget);
    });
  });

  group('wide layout (web / Windows)', () {
    Future<void> openGrid(WidgetTester tester) async {
      await tester.tap(find.text('Grid'));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('deck view: rail, note list, deck and counter', (tester) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      // Every note is listed next to the deck.
      expect(find.byKey(const Key('deck-item-T1')), findsOneWidget);
      expect(find.byKey(const Key('deck-item-T2')), findsOneWidget);
      expect(find.byKey(const Key('deck-item-T3')), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.textContaining('Swipe left'), findsNothing);
    });

    testWidgets('clicking a note in the list jumps the deck to it', (
      tester,
    ) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('deck-item-T3')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck-item-T2')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('arrow keys and next / previous move through the deck', (
      tester,
    ) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 500));
      // Wraps around to the last note.
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck-next')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('grid view shows action cards and the stats panel', (
      tester,
    ) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await openGrid(tester);
      expect(find.text('Pay rent'), findsWidgets);
      expect(find.text('Plan trip'), findsWidgets);
      expect(find.text('Buy milk'), findsWidgets);
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('Up next'), findsOneWidget);
      expect(find.byTooltip('Complete'), findsWidgets);
      await settleTimers(tester);
    });

    testWidgets('complete from the card, then undo', (tester) async {
      setSize(tester, 1100, 900);
      final (provider, service) = await pumpApp(tester);
      await openGrid(tester);
      await tester.tap(find.byTooltip('Complete').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.all.where((t) => t.isCompleted).length, 2);
      expect(find.text('Task completed!'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.all.where((t) => t.isCompleted).length, 1);
      expect(provider.todos.length, 3);
    });

    testWidgets('delete asks first and can be undone', (tester) async {
      setSize(tester, 1100, 900);
      final (_, service) = await pumpApp(tester);
      await openGrid(tester);
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Are you sure'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.all.length, 3);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.all.length, 4);
    });

    testWidgets('cancelling the dialog keeps the task', (tester) async {
      setSize(tester, 1100, 900);
      final (_, service) = await pumpApp(tester);
      await openGrid(tester);
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.all.length, 4);
    });

    testWidgets('priority chip filters the list and the deck', (tester) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('chip-priority-high')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('deck-item-T1')), findsOneWidget);
      expect(find.byKey(const Key('deck-item-T3')), findsNothing);
      expect(find.text('1 / 1'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('deck-item-T3')), findsOneWidget);
      await settleTimers(tester);
    });

    testWidgets('search finds the note and shows it in the deck', (
      tester,
    ) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await tester.enterText(find.byKey(const Key('search-field')), 'milk');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.byKey(const Key('deck-item-T3')), findsOneWidget);
      expect(find.byKey(const Key('deck-item-T1')), findsNothing);
      await settleTimers(tester);
    });

    testWidgets('pin moves a task to the front', (tester) async {
      setSize(tester, 1100, 1500);
      final (provider, _) = await pumpApp(tester);
      await openGrid(tester);
      expect(provider.visibleTodos.first.taskId, 'T1');
      await tester.tap(find.byTooltip('Pin').last); // Buy milk
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(provider.visibleTodos.first.taskId, 'T3');
    });

    testWidgets('navigation rail switches sections', (tester) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester);
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Completed Tasks'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('aarav@example.com'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester, todos: []);
      expect(find.text('No tasks yet'), findsWidgets);
    });

    testWidgets('completed screen can be shown on its own, wide', (
      tester,
    ) async {
      setSize(tester, 1100, 900);
      await pumpApp(tester, home: const CompletedTodosScreen());
      expect(find.text('Completed Tasks'), findsOneWidget);
    });
  });

  group('sign in screen', () {
    testWidgets('keeps the form narrow on a wide window', (tester) async {
      setSize(tester, 1400, 900);
      await pumpApp(tester, home: const LoginScreen());
      final width = tester.getSize(find.byType(Form)).width;
      expect(width, lessThanOrEqualTo(440));
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('validates empty fields', (tester) async {
      setSize(tester, 430, 932);
      await pumpApp(tester, home: const LoginScreen());
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('wrong password shows the error', (tester) async {
      setSize(tester, 430, 932);
      final service = FakeAuthService()..accounts['a@b.co'] = 'secret1';
      final todos = newTodos(FakeTodoService());
      await tester.pumpWidget(
        testApp(
          auth: signedInAuthFor(service),
          todos: todos,
          home: const LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Wrong password provided.'), findsOneWidget);
    });
  });

  testWidgets('context.read works for the provider', (tester) async {
    setSize(tester, 430, 932);
    await pumpApp(tester);
    final p = tester.element(find.byType(HomeScreen)).read<TodoProvider>();
    expect(p.todos.length, 3);
  });
}
