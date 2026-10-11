import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:deck_note/widgets/todo_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// Keeps track of which note is on top of the deck and lets the rest of the
/// UI (counter, overview sheet, side list, keyboard) move it.
class DeckNavigator extends ChangeNotifier {
  final CardSwiperController swiper = CardSwiperController();

  int _index = 0;
  int _count = 0;

  /// Position of the note on top of the deck (0 based).
  int get index => _count == 0 ? 0 : _index.clamp(0, _count - 1);
  int get count => _count;

  /// Called by the deck whenever the number of notes changes.
  void syncCount(int count) {
    _count = count;
    if (_count > 0 && _index >= _count) _index = _count - 1;
  }

  /// Put the note at [i] on top of the deck.
  void jumpTo(int i) {
    if (_count == 0) return;
    final target = i.clamp(0, _count - 1);
    _index = target;
    swiper.moveTo(target);
    notifyListeners();
  }

  /// Next / previous note; wraps around so no note is ever out of reach.
  void next() => _count == 0 ? null : jumpTo((index + 1) % _count);
  void previous() => _count == 0 ? null : jumpTo((index - 1 + _count) % _count);

  /// Remember which card should be on top after the deck is rebuilt.
  void swiped(int newIndex) {
    _index = newIndex;
  }

  void reset() {
    _index = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    swiper.dispose();
    super.dispose();
  }
}

/// The swipeable deck. Cards loop, so swiping never loses a note: right
/// completes (undoable), left asks before deleting (undoable).
class TaskDeck extends StatelessWidget {
  final List<TodoModel> todos;
  final DeckNavigator navigator;
  final bool showActions;
  final bool Function(int previousIndex, CardSwiperDirection direction)
  onSwipe;

  const TaskDeck({
    super.key,
    required this.todos,
    required this.navigator,
    required this.onSwipe,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    navigator.syncCount(todos.length);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): navigator.previous,
        const SingleActivator(LogicalKeyboardKey.arrowUp): navigator.previous,
        const SingleActivator(LogicalKeyboardKey.arrowRight): navigator.next,
        const SingleActivator(LogicalKeyboardKey.arrowDown): navigator.next,
      },
      child: Focus(
        autofocus: true,
        child: Listener(
          // Mouse wheel / trackpad scroll flips through the deck.
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              event.scrollDelta.dy > 0 ? navigator.next() : navigator.previous();
            }
          },
          child: CardSwiper(
            key: ValueKey(Object.hashAll(todos.map((t) => t.taskId))),
            controller: navigator.swiper,
            initialIndex: navigator.index,
            cardsCount: todos.length,
            isLoop: true,
            numberOfCardsDisplayed: todos.length > 3 ? 3 : todos.length,
            backCardOffset: const Offset(0, 50),
            padding: const EdgeInsets.all(0),
            scale: 0.9,
            cardBuilder: (context, index, px, py) =>
                TodoCard(todo: todos[index], showActions: showActions),
            onSwipe: (previous, current, direction) =>
                onSwipe(previous, direction),
            allowedSwipeDirection: const AllowedSwipeDirection.only(
              left: true,
              right: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// `<  3 / 12  >` - the counter opens the overview of every note.
class DeckControls extends StatelessWidget {
  final DeckNavigator navigator;
  final List<TodoModel> todos;

  const DeckControls({super.key, required this.navigator, required this.todos});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: navigator,
      builder: (context, _) {
        final i = navigator.index;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('deck-prev'),
              tooltip: 'Previous note',
              onPressed: todos.length < 2 ? null : navigator.previous,
              icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 18),
            ),
            TextButton.icon(
              key: const Key('deck-overview'),
              onPressed: todos.isEmpty
                  ? null
                  : () => showDeckOverview(
                      context,
                      todos,
                      navigator,
                      context.read<TodoProvider>().now,
                    ),
              icon: const FaIcon(FontAwesomeIcons.tableList, size: 14),
              label: Text(
                '${todos.isEmpty ? 0 : i + 1} / ${todos.length}',
                key: const Key('deck-counter'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              key: const Key('deck-next'),
              tooltip: 'Next note',
              onPressed: todos.length < 2 ? null : navigator.next,
              icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 18),
            ),
          ],
        );
      },
    );
  }
}

/// One row of the note list (overview sheet and the wide side list).
class DeckListTile extends StatelessWidget {
  final TodoModel todo;
  final int number;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  const DeckListTile({
    super.key,
    required this.todo,
    required this.number,
    required this.selected,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.cardColorAt(todo.colorIndex);
    final overdue = todo.isOverdue(now);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: selected
                  ? color
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (todo.dueDate != null)
                      Text(
                        dueLabel(todo, now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue ? AppTheme.danger : Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              if (todo.pinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FaIcon(
                    FontAwesomeIcons.thumbtack,
                    size: 12,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.priorityColor(todo.priority),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable list of every note in the deck; tapping one jumps to it.
class DeckList extends StatelessWidget {
  final List<TodoModel> todos;
  final DeckNavigator navigator;
  final DateTime now;
  final VoidCallback? onPicked;

  const DeckList({
    super.key,
    required this.todos,
    required this.navigator,
    required this.now,
    this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: navigator,
      builder: (context, _) => ListView.builder(
        shrinkWrap: onPicked != null,
        itemCount: todos.length,
        itemBuilder: (context, i) => DeckListTile(
          key: ValueKey('deck-item-${todos[i].taskId}'),
          todo: todos[i],
          number: i + 1,
          selected: i == navigator.index,
          now: now,
          onTap: () {
            navigator.jumpTo(i);
            onPicked?.call();
          },
        ),
      ),
    );
  }
}

/// Bottom sheet with all notes; pick one to bring it to the top.
Future<void> showDeckOverview(
  BuildContext context,
  List<TodoModel> todos,
  DeckNavigator navigator,
  DateTime now,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.surfaceColor, AppTheme.cardColor],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All notes (${todos.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: navigator,
                builder: (context, _) => ListView.builder(
                  controller: scroll,
                  itemCount: todos.length,
                  itemBuilder: (context, i) => DeckListTile(
                    key: ValueKey('overview-item-${todos[i].taskId}'),
                    todo: todos[i],
                    number: i + 1,
                    selected: i == navigator.index,
                    now: now,
                    onTap: () {
                      navigator.jumpTo(i);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
