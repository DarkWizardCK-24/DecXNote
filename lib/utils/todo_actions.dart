import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// A floating snack bar with an icon and an optional action (e.g. Undo).
void showAppSnack(
  BuildContext context,
  String message, {
  FaIconData? icon,
  Color color = AppTheme.success,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            FaIcon(icon, color: color, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(message)),
        ],
      ),
      duration: duration,
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Marks a task done and offers to undo it.
Future<void> completeWithUndo(BuildContext context, TodoModel todo) async {
  final provider = context.read<TodoProvider>();
  final ok = await provider.completeTodo(todo.taskId);
  if (!context.mounted || !ok) return;
  showAppSnack(
    context,
    'Task completed!',
    icon: FontAwesomeIcons.circleCheck,
    actionLabel: 'Undo',
    onAction: () => provider.markAsIncomplete(todo.taskId),
  );
}

/// Asks for confirmation, deletes, and offers to undo.
Future<void> confirmAndDelete(
  BuildContext context,
  TodoModel todo, {
  bool permanent = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: AppTheme.warning,
            size: 24,
          ),
          SizedBox(width: 10),
          Text('Delete Task'),
        ],
      ),
      content: Text(
        permanent
            ? 'Are you sure you want to permanently delete "${todo.title}"?'
            : 'Are you sure you want to delete "${todo.title}"?',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final provider = context.read<TodoProvider>();
  final ok = await provider.deleteTodo(todo.taskId);
  if (!context.mounted || !ok) return;
  showAppSnack(
    context,
    'Task deleted',
    icon: FontAwesomeIcons.trash,
    color: AppTheme.accentColor,
    actionLabel: 'Undo',
    onAction: () => provider.restoreTodo(todo),
  );
}
