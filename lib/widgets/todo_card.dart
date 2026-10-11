import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_actions.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'edit_todo_dialog.dart';

/// A task as a glass card. On phones it is a card in the swiper; on wide
/// screens it sits in a grid and shows action buttons (set [showActions]).
class TodoCard extends StatelessWidget {
  final TodoModel todo;
  final bool showActions;

  const TodoCard({super.key, required this.todo, this.showActions = false});

  FaIconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return FontAwesomeIcons.circleExclamation;
      case Priority.medium:
        return FontAwesomeIcons.circleInfo;
      case Priority.low:
        return FontAwesomeIcons.circleMinus;
    }
  }

  Future<void> _toggleChecklistItem(
    BuildContext context,
    ChecklistItem item,
  ) async {
    final todoProvider = context.read<TodoProvider>();

    final updatedChecklist = todo.checklist.map((i) {
      if (i.id == item.id) {
        return i.copyWith(isCompleted: !i.isCompleted);
      }
      return i;
    }).toList();

    await todoProvider.updateChecklistItems(todo.taskId, updatedChecklist);

    // When every checklist item is ticked the task completes itself.
    final allCompleted = updatedChecklist.every((i) => i.isCompleted);
    if (allCompleted && updatedChecklist.isNotEmpty) {
      await todoProvider.completeTodo(todo.taskId);
      if (context.mounted) {
        showAppSnack(
          context,
          'All checklist items done!',
          icon: FontAwesomeIcons.trophy,
          actionLabel: 'Undo',
          onAction: () => todoProvider.markAsIncomplete(todo.taskId),
        );
      }
    }
  }

  Widget _chip(FaIconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String tooltip,
    FaIconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: FaIcon(icon, size: 16, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = AppTheme.cardColorAt(todo.colorIndex);
    final priorityColor = AppTheme.priorityColor(todo.priority);
    final now = context.read<TodoProvider>().now;
    final overdue = todo.isOverdue(now);
    final dueColor = overdue
        ? const Color(0xFFFFC9D1)
        : (todo.isDueToday(now) ? const Color(0xFFFFE0A3) : Colors.white70);

    final card = GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => EditTodoDialog(todo: todo),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.25),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: double.infinity,
          borderRadius: AppTheme.radiusL,
          blur: 15,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.25),
              cardColor.withValues(alpha: 0.15),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.4),
              cardColor.withValues(alpha: 0.2),
            ],
          ),
          child: Stack(
            children: [
              if (!showActions)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(showActions ? 20 : 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chip(
                          _getPriorityIcon(todo.priority),
                          todo.priority.name.toUpperCase(),
                          priorityColor,
                        ),
                        if (todo.pinned) ...[
                          const SizedBox(width: 8),
                          const FaIcon(
                            FontAwesomeIcons.thumbtack,
                            size: 14,
                            color: AppTheme.secondaryColor,
                          ),
                        ],
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(right: showActions ? 0 : 44),
                          child: Text(
                            todo.taskId,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: showActions ? 14 : 20),
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: showActions ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: showActions ? 10 : 15),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.description,
                              style: TextStyle(
                                fontSize: showActions ? 14 : 16,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.5,
                              ),
                            ),
                            if (todo.checklist.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildChecklist(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 6),
                    if (todo.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            FaIcon(
                              overdue
                                  ? FontAwesomeIcons.fire
                                  : FontAwesomeIcons.calendarDay,
                              size: 14,
                              color: dueColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${dueLabel(todo, now)} - ${DateFormat('MMM dd').format(todo.dueDate!)}',
                                key: const Key('due-label'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: dueColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          showActions
                              ? DateFormat('MMM dd').format(todo.createdAt)
                              : 'Created: ${DateFormat('MMM dd, yyyy').format(todo.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (showActions) ...[
                          const Spacer(),
                          _actionButton(
                            todo.pinned ? 'Unpin' : 'Pin',
                            FontAwesomeIcons.thumbtack,
                            todo.pinned
                                ? AppTheme.secondaryColor
                                : Colors.white70,
                            () => context.read<TodoProvider>().togglePinned(
                              todo,
                            ),
                          ),
                          _actionButton(
                            'Complete',
                            FontAwesomeIcons.circleCheck,
                            AppTheme.success,
                            () => completeWithUndo(context, todo),
                          ),
                          _actionButton(
                            'Delete',
                            FontAwesomeIcons.trash,
                            AppTheme.accentColor,
                            () => confirmAndDelete(context, todo),
                          ),
                        ],
                      ],
                    ),
                    if (todo.updatedAt != null && !showActions) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Updated: ${DateFormat('MMM dd, yyyy').format(todo.updatedAt!)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Grid cards are built lazily while scrolling, so they skip the entrance
    // animation (it would not start until the next frame).
    if (showActions) return card;
    return card.animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildChecklist(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.listCheck,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              const Text(
                'Checklist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${todo.checklist.where((i) => i.isCompleted).length}/${todo.checklist.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...todo.checklist.map((item) {
            return GestureDetector(
              onTap: () => _toggleChecklistItem(context, item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? AppTheme.success
                            : Colors.transparent,
                        border: Border.all(
                          color: item.isCompleted
                              ? AppTheme.success
                              : Colors.white60,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: item.isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: item.isCompleted
                              ? Colors.white60
                              : Colors.white,
                          fontSize: 14,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
