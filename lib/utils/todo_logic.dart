import 'package:deck_note/models/todo_model.dart';

enum DueFilter { any, overdue, today, upcoming, noDate }

enum TodoSort { smart, newest, dueDate, priority, title }

extension DueFilterLabel on DueFilter {
  String get label => switch (this) {
    DueFilter.any => 'All',
    DueFilter.overdue => 'Overdue',
    DueFilter.today => 'Today',
    DueFilter.upcoming => 'Upcoming',
    DueFilter.noDate => 'No date',
  };
}

extension TodoSortLabel on TodoSort {
  String get label => switch (this) {
    TodoSort.smart => 'Smart',
    TodoSort.newest => 'Newest',
    TodoSort.dueDate => 'Due date',
    TodoSort.priority => 'Priority',
    TodoSort.title => 'Title A-Z',
  };
}

/// What the user typed / picked to narrow the task list.
class TodoQuery {
  final String text;
  final Priority? priority;
  final DueFilter due;
  final TodoSort sort;

  const TodoQuery({
    this.text = '',
    this.priority,
    this.due = DueFilter.any,
    this.sort = TodoSort.smart,
  });

  bool get isFiltering =>
      text.trim().isNotEmpty || priority != null || due != DueFilter.any;

  TodoQuery copyWith({
    String? text,
    Priority? priority,
    bool clearPriority = false,
    DueFilter? due,
    TodoSort? sort,
  }) => TodoQuery(
    text: text ?? this.text,
    priority: clearPriority ? null : (priority ?? this.priority),
    due: due ?? this.due,
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is TodoQuery &&
      other.text == text &&
      other.priority == priority &&
      other.due == due &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(text, priority, due, sort);
}

bool _matchesDue(TodoModel t, DueFilter f, DateTime now) => switch (f) {
  DueFilter.any => true,
  DueFilter.overdue => t.isOverdue(now),
  DueFilter.today => t.isDueToday(now),
  DueFilter.upcoming =>
    t.dueDate != null && !t.isOverdue(now) && !t.isDueToday(now),
  DueFilter.noDate => t.dueDate == null,
};

bool _matchesText(TodoModel t, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return t.title.toLowerCase().contains(q) ||
      t.description.toLowerCase().contains(q) ||
      t.taskId.toLowerCase().contains(q) ||
      t.checklist.any((c) => c.text.toLowerCase().contains(q));
}

int _byRecent(TodoModel a, TodoModel b) =>
    (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt);

int _byDue(TodoModel a, TodoModel b) {
  if (a.dueDate == null && b.dueDate == null) return _byRecent(a, b);
  if (a.dueDate == null) return 1;
  if (b.dueDate == null) return -1;
  final c = a.dueDate!.compareTo(b.dueDate!);
  return c != 0 ? c : _byRecent(a, b);
}

/// Filters and sorts [todos]. Pinned tasks always come first.
List<TodoModel> applyQuery(
  List<TodoModel> todos,
  TodoQuery query,
  DateTime now,
) {
  final result = todos
      .where(
        (t) =>
            _matchesText(t, query.text) &&
            (query.priority == null || t.priority == query.priority) &&
            _matchesDue(t, query.due, now),
      )
      .toList();

  int cmp(TodoModel a, TodoModel b) {
    switch (query.sort) {
      case TodoSort.newest:
        return _byRecent(a, b);
      case TodoSort.dueDate:
        return _byDue(a, b);
      case TodoSort.priority:
        final c = b.priority.index.compareTo(a.priority.index);
        return c != 0 ? c : _byDue(a, b);
      case TodoSort.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case TodoSort.smart:
        final ao = a.isOverdue(now) ? 0 : 1;
        final bo = b.isOverdue(now) ? 0 : 1;
        if (ao != bo) return ao - bo;
        final c = _byDue(a, b);
        return c != 0 ? c : b.priority.index.compareTo(a.priority.index);
    }
  }

  result.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return cmp(a, b);
  });
  return result;
}

/// Numbers for the summary panels.
class TodoStats {
  final int active;
  final int completed;
  final int overdue;
  final int dueToday;
  final int highPriority;
  final int completedThisWeek;

  const TodoStats({
    required this.active,
    required this.completed,
    required this.overdue,
    required this.dueToday,
    required this.highPriority,
    required this.completedThisWeek,
  });

  int get total => active + completed;

  /// 0..1 share of all tasks that are done.
  double get completionRate => total == 0 ? 0 : completed / total;

  factory TodoStats.from(
    List<TodoModel> active,
    List<TodoModel> completed,
    DateTime now,
  ) {
    final weekAgo = now.subtract(const Duration(days: 7));
    return TodoStats(
      active: active.length,
      completed: completed.length,
      overdue: active.where((t) => t.isOverdue(now)).length,
      dueToday: active.where((t) => t.isDueToday(now)).length,
      highPriority: active.where((t) => t.priority == Priority.high).length,
      completedThisWeek: completed
          .where(
            (t) => t.completedAt != null && t.completedAt!.isAfter(weekAgo),
          )
          .length,
    );
  }
}

/// "Overdue by 2 days", "Due today", "Due tomorrow", "Due in 5 days".
String dueLabel(TodoModel t, DateTime now) {
  final d = t.daysUntilDue(now);
  if (d == null) return '';
  if (d < 0) return d == -1 ? 'Overdue by 1 day' : 'Overdue by ${-d} days';
  if (d == 0) return 'Due today';
  if (d == 1) return 'Due tomorrow';
  return 'Due in $d days';
}
