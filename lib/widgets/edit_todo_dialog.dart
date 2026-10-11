import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/widgets/todo_form_dialog.dart';
import 'package:flutter/widgets.dart';

/// Dialog for editing a task.
class EditTodoDialog extends StatelessWidget {
  final TodoModel todo;

  const EditTodoDialog({super.key, required this.todo});

  @override
  Widget build(BuildContext context) => TodoFormDialog(todo: todo);
}
