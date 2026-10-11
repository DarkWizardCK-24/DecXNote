import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/completed_todos_screen.dart';
import 'package:deck_note/screens/profile_screen.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:deck_note/widgets/app_logo.dart';
import 'package:deck_note/widgets/edit_todo_dialog.dart';
import 'package:deck_note/widgets/filter_bar.dart';
import 'package:deck_note/widgets/stats_panel.dart';
import 'package:deck_note/widgets/task_deck.dart';
import 'package:deck_note/widgets/todo_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The desktop / web layout: a navigation rail, a grid of task cards and a
/// side panel with progress and what is due next.
class WideHome extends StatelessWidget {
  final int section;
  final ValueChanged<int> onSection;
  final VoidCallback onAdd;
  final DeckNavigator navigator;
  final bool Function(int previousIndex, CardSwiperDirection direction)
  onSwipe;

  const WideHome({
    super.key,
    required this.section,
    required this.onSection,
    required this.onAdd,
    required this.navigator,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = context.select<TodoProvider, int>(
      (p) => p.completedTodos.length,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: section,
              onDestinationSelected: onSection,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppLogo(size: 48, glow: AppTheme.primaryColor),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: FaIcon(FontAwesomeIcons.layerGroup, size: 20),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: completedCount > 0,
                    label: Text('$completedCount'),
                    backgroundColor: AppTheme.success,
                    textColor: AppTheme.backgroundColor,
                    child: const FaIcon(FontAwesomeIcons.circleCheck, size: 20),
                  ),
                  label: const Text('Completed'),
                ),
                const NavigationRailDestination(
                  icon: FaIcon(FontAwesomeIcons.user, size: 20),
                  label: Text('Profile'),
                ),
              ],
            ),
            VerticalDivider(
              width: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: switch (section) {
                1 => const CompletedTodosScreen(embedded: true),
                2 => const ProfileScreen(embedded: true),
                _ => _TasksPane(
                  onAdd: onAdd,
                  navigator: navigator,
                  onSwipe: onSwipe,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksPane extends StatefulWidget {
  final VoidCallback onAdd;
  final DeckNavigator navigator;
  final bool Function(int previousIndex, CardSwiperDirection direction)
  onSwipe;

  const _TasksPane({
    required this.onAdd,
    required this.navigator,
    required this.onSwipe,
  });

  @override
  State<_TasksPane> createState() => _TasksPaneState();
}

class _TasksPaneState extends State<_TasksPane> {
  bool _deckView = true;

  @override
  Widget build(BuildContext context) {
    final onAdd = widget.onAdd;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DecXNote',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Consumer2<AuthProvider, TodoProvider>(
                      builder: (context, auth, todos, _) => Text(
                        'Hi, ${auth.user?.name ?? "User"} - '
                        '${todos.todos.length} open '
                        '${todos.todos.length == 1 ? "task" : "tasks"}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<bool>(
                key: const Key('view-toggle'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: FaIcon(FontAwesomeIcons.layerGroup, size: 14),
                    label: Text('Deck'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: FaIcon(FontAwesomeIcons.tableCells, size: 14),
                    label: Text('Grid'),
                  ),
                ],
                selected: {_deckView},
                onSelectionChanged: (v) => setState(() => _deckView = v.first),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                key: const Key('add-task'),
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                label: const Text('Add Task'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: TodoFilterBar(),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _deckView
                ? _DeckView(
                    navigator: widget.navigator,
                    onSwipe: widget.onSwipe,
                  )
                : const _GridView(),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Consumer<TodoProvider>(
          builder: (context, p, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatsPanel(stats: p.stats),
              const SizedBox(height: 20),
              _UpNext(todos: p.todos, now: p.now),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TaskGrid()),
        SizedBox(width: 24),
        _SidePanel(),
      ],
    );
  }
}

/// All notes in a list on the left, the deck in the middle (with previous /
/// next, a counter and arrow-key support), and - when there is room - the
/// progress panel on the right.
class _DeckView extends StatelessWidget {
  final DeckNavigator navigator;
  final bool Function(int previousIndex, CardSwiperDirection direction)
  onSwipe;

  const _DeckView({required this.navigator, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    final showPanel = MediaQuery.sizeOf(context).width >= 1240;
    return Consumer<TodoProvider>(
      builder: (context, p, _) {
        if (p.error != null) {
          return Center(
            child: Text(
              'Error loading tasks: ${p.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        if (p.todos.isEmpty) {
          return const _Empty(
            icon: FontAwesomeIcons.clipboardList,
            title: 'No tasks yet',
            hint: 'Use "Add Task" to create your first one',
          );
        }
        final visible = p.visibleTodos;
        if (visible.isEmpty) {
          return _Empty(
            icon: FontAwesomeIcons.magnifyingGlass,
            title: 'No matching tasks',
            hint: 'Try a different search or clear the filters',
            action: TextButton(
              onPressed: p.clearFilters,
              child: const Text('Clear filters'),
            ),
          );
        }
        navigator.syncCount(visible.length);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: DeckList(
                todos: visible,
                navigator: navigator,
                now: p.now,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      DeckControls(navigator: navigator, todos: visible),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TaskDeck(
                            todos: visible,
                            navigator: navigator,
                            onSwipe: onSwipe,
                            showActions: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showPanel) ...[const SizedBox(width: 24), const _SidePanel()],
          ],
        );
      },
    );
  }
}

class _TaskGrid extends StatelessWidget {
  const _TaskGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, p, _) {
        if (p.error != null) {
          return Center(
            child: Text(
              'Error loading tasks\n${p.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        if (p.todos.isEmpty) {
          return const _Empty(
            icon: FontAwesomeIcons.clipboardList,
            title: 'No tasks yet',
            hint: 'Use "Add Task" to create your first one',
          );
        }
        final visible = p.visibleTodos;
        if (visible.isEmpty) {
          return _Empty(
            icon: FontAwesomeIcons.magnifyingGlass,
            title: 'No matching tasks',
            hint: 'Try a different search or clear the filters',
            action: TextButton(
              onPressed: p.clearFilters,
              child: const Text('Clear filters'),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 440,
            mainAxisExtent: 360,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: visible.length,
          itemBuilder: (context, i) =>
              TodoCard(key: ValueKey(visible[i].taskId), todo: visible[i], showActions: true),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String hint;
  final Widget? action;

  const _Empty({
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(color: Colors.white70)),
          ?action,
        ],
      ),
    );
  }
}

/// The next few tasks with a due date.
class _UpNext extends StatelessWidget {
  final List<TodoModel> todos;
  final DateTime now;

  const _UpNext({required this.todos, required this.now});

  @override
  Widget build(BuildContext context) {
    final upcoming = todos.where((t) => t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final shown = upcoming.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Up next',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const Text(
              'Nothing has a due date yet.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          for (final t in shown)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showDialog(
                context: context,
                builder: (_) => EditTodoDialog(todo: t),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.priorityColor(t.priority),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${dueLabel(t, now)} - ${DateFormat('MMM dd').format(t.dueDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: t.isOverdue(now)
                                  ? AppTheme.danger
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
