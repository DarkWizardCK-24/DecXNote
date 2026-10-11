// Generates the README screenshots from the real screens using sample data
// (no Firebase needed). Skipped during a normal `flutter test`; run with:
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// PNGs are written to docs/screenshots/. All data below is made up.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/completed_todos_screen.dart';
import 'package:deck_note/screens/home_screen.dart';
import 'package:deck_note/screens/login_screen.dart';
import 'package:deck_note/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';

const bool _enabled = bool.fromEnvironment('SCREENSHOTS');
final _boundaryKey = GlobalKey();

DateTime _in(int days) => testNow.add(Duration(days: days));

List<TodoModel> showcaseTodos() => [
  sampleTodo(
    id: 'TASK000001',
    title: 'Pay the electricity bill',
    description: 'Due at the end of the week, avoid the late fee.',
    priority: Priority.high,
    dueDate: _in(-2),
    colorIndex: 0,
  ),
  sampleTodo(
    id: 'TASK000002',
    title: 'Plan the Goa trip',
    description: 'Flights, hotel and a rough itinerary for four days.',
    priority: Priority.medium,
    dueDate: _in(5),
    pinned: true,
    colorIndex: 2,
    checklist: [
      ChecklistItem(id: 'a', text: 'Compare flight prices', isCompleted: true),
      ChecklistItem(id: 'b', text: 'Book the hotel'),
      ChecklistItem(id: 'c', text: 'Renew passport'),
    ],
  ),
  sampleTodo(
    id: 'TASK000003',
    title: 'Team standup notes',
    description: 'Write up blockers and share with the team before 11.',
    priority: Priority.high,
    dueDate: testNow,
    colorIndex: 5,
  ),
  sampleTodo(
    id: 'TASK000004',
    title: 'Buy groceries',
    description: 'Milk, eggs, coffee beans, fruit for the week.',
    priority: Priority.low,
    colorIndex: 3,
    checklist: [
      ChecklistItem(id: 'd', text: 'Milk'),
      ChecklistItem(id: 'e', text: 'Coffee beans'),
    ],
  ),
  sampleTodo(
    id: 'TASK000005',
    title: 'Read two chapters',
    description: 'Finish the design patterns book this month.',
    priority: Priority.low,
    dueDate: _in(12),
    colorIndex: 4,
  ),
  sampleTodo(
    id: 'TASK000006',
    title: 'Book dentist appointment',
    description: 'Ask about the Saturday morning slots.',
    priority: Priority.medium,
    dueDate: _in(2),
    colorIndex: 7,
  ),
  sampleTodo(
    id: 'TASK000007',
    title: 'Fix the login bug',
    description: 'Users on Safari see a blank screen after signing in.',
    priority: Priority.high,
    dueDate: _in(1),
    colorIndex: 9,
  ),
  sampleTodo(
    id: 'TASK000008',
    title: 'Water the plants',
    description: 'Balcony plants need water twice a week.',
    priority: Priority.low,
    colorIndex: 8,
  ),
  sampleTodo(
    id: 'TASK000101',
    title: 'Send the invoice',
    description: 'March invoice to the design client.',
    completed: true,
    completedAt: _in(-1),
    colorIndex: 1,
  ),
  sampleTodo(
    id: 'TASK000102',
    title: 'Renew car insurance',
    description: 'Compared three quotes and picked the cheapest.',
    completed: true,
    completedAt: _in(-2),
    colorIndex: 6,
  ),
  sampleTodo(
    id: 'TASK000103',
    title: 'Call the plumber',
    description: 'Kitchen tap is fixed.',
    completed: true,
    completedAt: _in(-4),
    colorIndex: 5,
  ),
  sampleTodo(
    id: 'TASK000104',
    title: 'Clean the inbox',
    description: 'Inbox zero for the first time this year.',
    completed: true,
    completedAt: _in(-9),
    colorIndex: 3,
  ),
];

Future<TodoProvider> _pump(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(430, 932),
  double dpr = 2,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  final todos = newTodos(FakeTodoService(showcaseTodos()));
  final auth = signedIn ? signedInAuth() : signedInAuthFor(FakeAuthService());
  await tester.pump();
  await tester.pump();

  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: testApp(auth: auth, todos: todos, home: home),
    ),
  );
  // Images decode asynchronously; load the logo before the first capture.
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/logo.png'),
      tester.element(find.byType(MaterialApp)),
    );
  });
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  return todos;
}

Future<void> _shot(WidgetTester tester, String name, {double dpr = 2}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  ScaffoldMessenger.maybeOf(
    tester.element(find.byType(Scaffold).first),
  )?.clearSnackBars();
  // Several frames: entrance animations start on the frame after a rebuild.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }

  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${image.width}x${image.height})');
  });
}

const _wide = Size(1100, 900);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_enabled) await loadAppFonts();
  });

  testWidgets('sign in', skip: !_enabled, (tester) async {
    await _pump(tester, home: const LoginScreen(), signedIn: false);
    await _shot(tester, '01-sign-in');
  });

  testWidgets('home deck', skip: !_enabled, (tester) async {
    await _pump(tester, home: const HomeScreen());
    await _shot(tester, '02-home');

    await tester.tap(find.byKey(const Key('deck-overview')));
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '03-jump-to-note');
  });

  testWidgets('search and filters', skip: !_enabled, (tester) async {
    await _pump(tester, home: const HomeScreen());
    await tester.tap(find.byKey(const Key('toggle-filters')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('chip-priority-high')));
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '04-search-filter');
  });

  testWidgets('add task', skip: !_enabled, (tester) async {
    await _pump(tester, home: const HomeScreen());
    await tester.tap(find.text('Add Task'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Prepare the demo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Slides, sample data and a quick dry run.',
    );
    await tester.tap(find.byKey(const Key('priority-high')));
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '05-add-task');
  });

  testWidgets('completed and stats', skip: !_enabled, (tester) async {
    final todos = await _pump(tester, home: const CompletedTodosScreen());
    todos.listenToTodos('USER000001');
    todos.listenToCompletedTodos('USER000001');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '06-completed-stats');
  });

  testWidgets('profile', skip: !_enabled, (tester) async {
    await _pump(tester, home: const ProfileScreen());
    await _shot(tester, '07-profile');
  });

  testWidgets('wide deck', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      home: const HomeScreen(),
      size: const Size(1280, 800),
      dpr: 1.5,
    );
    await tester.tap(find.byKey(const Key('deck-item-TASK000007')));
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '08-wide-deck', dpr: 1.5);
  });

  testWidgets('wide grid', skip: !_enabled, (tester) async {
    await _pump(tester, home: const HomeScreen(), size: _wide, dpr: 1.5);
    await tester.tap(find.text('Grid'));
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '09-wide-grid', dpr: 1.5);
  });

  testWidgets('wide completed', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      home: const HomeScreen(initialSection: 1),
      size: _wide,
      dpr: 1.5,
    );
    await _shot(tester, '10-wide-completed', dpr: 1.5);
  });

  testWidgets('wide profile', skip: !_enabled, (tester) async {
    await _pump(
      tester,
      home: const HomeScreen(initialSection: 2),
      size: _wide,
      dpr: 1.5,
    );
    await _shot(tester, '11-wide-profile', dpr: 1.5);
  });
}
