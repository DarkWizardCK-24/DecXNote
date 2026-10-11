import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  final now = testNow;
  DateTime days(int n) => now.add(Duration(days: n));

  group('TodoModel', () {
    test('missing new fields default sanely (old documents)', () {
      final t = TodoModel.fromMap({
        'taskId': 'TASK000007',
        'userId': 'USER000001',
        'title': 'Old task',
        'description': 'Written before due dates existed',
        'priority': 'high',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      expect(t.dueDate, isNull);
      expect(t.pinned, isFalse);
      expect(t.colorIndex, 0);
      expect(t.priority, Priority.high);
      expect(t.checklist, isEmpty);
    });

    test('bad values fall back instead of throwing', () {
      final t = TodoModel.fromMap({
        'priority': 42,
        'colorIndex': 'nope',
      });
      expect(t.priority, Priority.medium);
      expect(t.colorIndex, 0);
    });

    test('toMap / fromMap round trip keeps due date and pin', () {
      final t = sampleTodo(dueDate: DateTime(2026, 11, 2), pinned: true);
      final back = TodoModel.fromMap(t.toMap());
      expect(back.dueDate, DateTime(2026, 11, 2));
      expect(back.pinned, isTrue);
      expect(back.title, t.title);
    });

    test('copyWith can clear the due date', () {
      final t = sampleTodo(dueDate: days(2));
      expect(t.copyWith(clearDueDate: true).dueDate, isNull);
      expect(t.copyWith(title: 'x').dueDate, t.dueDate);
    });

    test('overdue / due today use whole days and ignore finished tasks', () {
      expect(sampleTodo(dueDate: days(-1)).isOverdue(now), isTrue);
      // Earlier today is not overdue yet.
      expect(
        sampleTodo(dueDate: DateTime(2026, 10, 13, 8)).isOverdue(now),
        isFalse,
      );
      expect(
        sampleTodo(dueDate: DateTime(2026, 10, 13, 8)).isDueToday(now),
        isTrue,
      );
      expect(sampleTodo().isOverdue(now), isFalse);
      expect(
        sampleTodo(dueDate: days(-5), completed: true).isOverdue(now),
        isFalse,
      );
    });
  });

  group('applyQuery', () {
    final list = [
      sampleTodo(id: 'A', title: 'Buy milk', priority: Priority.low),
      sampleTodo(
        id: 'B',
        title: 'Pay rent',
        priority: Priority.high,
        dueDate: days(-2),
      ),
      sampleTodo(
        id: 'C',
        title: 'Plan trip',
        description: 'Flights and hotel',
        dueDate: days(5),
        checklist: [ChecklistItem(id: '1', text: 'Book passport slot')],
      ),
      sampleTodo(
        id: 'D',
        title: 'Gym',
        priority: Priority.high,
        dueDate: DateTime(2026, 10, 13),
        pinned: true,
      ),
    ];

    List<String> ids(TodoQuery q) =>
        applyQuery(list, q, now).map((t) => t.taskId).toList();

    test('search looks at title, description and checklist, any case', () {
      expect(ids(const TodoQuery(text: 'MILK')), ['A']);
      expect(ids(const TodoQuery(text: 'hotel')), ['C']);
      expect(ids(const TodoQuery(text: 'passport')), ['C']);
      expect(ids(const TodoQuery(text: 'nothing like this')), isEmpty);
    });

    test('priority filter', () {
      expect(
        ids(const TodoQuery(priority: Priority.high)).toSet(),
        {'B', 'D'},
      );
    });

    test('due filters', () {
      expect(ids(const TodoQuery(due: DueFilter.overdue)), ['B']);
      expect(ids(const TodoQuery(due: DueFilter.today)), ['D']);
      expect(ids(const TodoQuery(due: DueFilter.upcoming)), ['C']);
      expect(ids(const TodoQuery(due: DueFilter.noDate)), ['A']);
    });

    test('filters combine', () {
      expect(
        ids(const TodoQuery(priority: Priority.high, due: DueFilter.overdue)),
        ['B'],
      );
    });

    test('pinned first, then overdue, then by due date (smart sort)', () {
      expect(ids(const TodoQuery()), ['D', 'B', 'C', 'A']);
    });

    test('other sorts keep pinned first', () {
      expect(ids(const TodoQuery(sort: TodoSort.title)), ['D', 'A', 'B', 'C']);
      expect(
        ids(const TodoQuery(sort: TodoSort.priority)),
        ['D', 'B', 'C', 'A'],
      );
      expect(
        ids(const TodoQuery(sort: TodoSort.dueDate)),
        ['D', 'B', 'C', 'A'],
      );
    });

    test('isFiltering ignores sort', () {
      expect(const TodoQuery(sort: TodoSort.title).isFiltering, isFalse);
      expect(const TodoQuery(text: ' x ').isFiltering, isTrue);
      expect(const TodoQuery(text: '   ').isFiltering, isFalse);
    });
  });

  group('TodoStats', () {
    test('counts and completion rate', () {
      final stats = TodoStats.from(
        [
          sampleTodo(id: '1', dueDate: days(-1), priority: Priority.high),
          sampleTodo(id: '2', dueDate: DateTime(2026, 10, 13)),
          sampleTodo(id: '3'),
        ],
        [
          sampleTodo(id: '4', completed: true, completedAt: days(-1)),
          sampleTodo(id: '5', completed: true, completedAt: days(-30)),
        ],
        now,
      );
      expect(stats.active, 3);
      expect(stats.completed, 2);
      expect(stats.total, 5);
      expect(stats.overdue, 1);
      expect(stats.dueToday, 1);
      expect(stats.highPriority, 1);
      expect(stats.completedThisWeek, 1);
      expect(stats.completionRate, closeTo(0.4, 1e-9));
    });

    test('no tasks means 0 percent, not NaN', () {
      expect(TodoStats.from([], [], now).completionRate, 0);
    });
  });

  test('dueLabel wording', () {
    expect(dueLabel(sampleTodo(dueDate: days(-3)), now), 'Overdue by 3 days');
    expect(dueLabel(sampleTodo(dueDate: days(-1)), now), 'Overdue by 1 day');
    expect(dueLabel(sampleTodo(dueDate: days(0)), now), 'Due today');
    expect(dueLabel(sampleTodo(dueDate: days(1)), now), 'Due tomorrow');
    expect(dueLabel(sampleTodo(dueDate: days(6)), now), 'Due in 6 days');
    expect(dueLabel(sampleTodo(), now), '');
  });
}
