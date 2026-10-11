import 'dart:math';

import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_actions.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Create (when [todo] is null) or edit a task.
class TodoFormDialog extends StatefulWidget {
  final TodoModel? todo;

  const TodoFormDialog({super.key, this.todo});

  @override
  State<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends State<TodoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _checklistController = TextEditingController();
  late Priority _selectedPriority;
  late List<ChecklistItem> _checklistItems;
  DateTime? _dueDate;
  late bool _pinned;
  final _uuid = const Uuid();

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _selectedPriority = t?.priority ?? Priority.medium;
    _checklistItems = List.of(t?.checklist ?? const []);
    _dueDate = t?.dueDate;
    _pinned = t?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklistItems.add(ChecklistItem(id: _uuid.v4(), text: text));
      _checklistController.clear();
    });
  }

  void _removeChecklistItem(String id) {
    setState(() => _checklistItems.removeWhere((item) => item.id == id));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final todoProvider = context.read<TodoProvider>();
    final bool success;
    if (_isEditing) {
      success = await todoProvider.updateTodo(
        widget.todo!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          checklist: _checklistItems,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          pinned: _pinned,
        ),
      );
    } else {
      success = await todoProvider.createTodo(
        userId: context.read<AuthProvider>().user!.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        checklist: _checklistItems,
        dueDate: _dueDate,
        pinned: _pinned,
      );
    }
    if (!mounted) return;
    if (success) {
      final messenger = context;
      Navigator.of(context).pop();
      if (messenger.mounted) {
        showAppSnack(
          messenger,
          _isEditing ? 'Task updated successfully!' : 'Task added successfully!',
          icon: FontAwesomeIcons.circleCheck,
        );
      }
    }
  }

  InputDecoration _decoration(String label, Widget icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: icon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = min(740.0, size.height - 80);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: height,
          borderRadius: AppTheme.radiusL,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceColor.withValues(alpha: 0.95),
              AppTheme.cardColor.withValues(alpha: 0.95),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing ? 'Edit Task' : 'Add New Task',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const FaIcon(
                          FontAwesomeIcons.xmark,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _decoration(
                              'Title',
                              const FaIcon(
                                FontAwesomeIcons.heading,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Please enter a title'
                                : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: _decoration(
                              'Description',
                              const Align(
                                alignment: Alignment.topLeft,
                                widthFactor: 1.0,
                                heightFactor: 1.0,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 12, top: 16),
                                  child: FaIcon(
                                    FontAwesomeIcons.alignLeft,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Please enter a description'
                                : null,
                          ),
                          const SizedBox(height: 15),
                          _label('Priority'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final p in Priority.values) ...[
                                _buildPriorityChip(p),
                                if (p != Priority.values.last)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 15),
                          _label('Due date'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const Key('pick-due-date'),
                                  onPressed: _pickDate,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusM,
                                      ),
                                    ),
                                  ),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.calendarDay,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _dueDate == null
                                        ? 'No due date'
                                        : DateFormat(
                                            'EEE, MMM dd, yyyy',
                                          ).format(_dueDate!),
                                  ),
                                ),
                              ),
                              if (_dueDate != null)
                                IconButton(
                                  tooltip: 'Remove due date',
                                  onPressed: () =>
                                      setState(() => _dueDate = null),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            key: const Key('pin-switch'),
                            contentPadding: EdgeInsets.zero,
                            value: _pinned,
                            onChanged: (v) => setState(() => _pinned = v),
                            activeThumbColor: AppTheme.primaryColor,
                            title: const Text('Pin to the top'),
                            secondary: const FaIcon(
                              FontAwesomeIcons.thumbtack,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _label('Checklist'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _checklistController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Add checklist item',
                                    hintStyle: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                    prefixIcon: const FaIcon(
                                      FontAwesomeIcons.listCheck,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusM,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _addChecklistItem(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: 'Add item',
                                onPressed: _addChecklistItem,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const FaIcon(
                                    FontAwesomeIcons.plus,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          for (final item in _checklistItems)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.circleCheck,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove item',
                                    onPressed: () =>
                                        _removeChecklistItem(item.id),
                                    icon: FaIcon(
                                      FontAwesomeIcons.trash,
                                      size: 14,
                                      color: AppTheme.danger.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Task' : 'Add Task',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut).fadeIn(),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildPriorityChip(Priority priority) {
    final color = AppTheme.priorityColor(priority);
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        key: Key('priority-${priority.name}'),
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Text(
            priority.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
