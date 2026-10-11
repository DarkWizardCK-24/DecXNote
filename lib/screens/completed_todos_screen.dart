import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/breakpoints.dart';
import 'package:deck_note/utils/todo_actions.dart';
import 'package:deck_note/widgets/edit_todo_dialog.dart';
import 'package:deck_note/widgets/stats_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:glassmorphism/glassmorphism.dart';

/// Finished tasks plus a progress summary. On phones it is its own page; on
/// wide screens it is a section of the main shell ([embedded]).
class CompletedTodosScreen extends StatelessWidget {
  final bool embedded;

  const CompletedTodosScreen({super.key, this.embedded = false});

  void _showOptionsBottomSheet(BuildContext context, TodoModel todo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.surfaceColor, AppTheme.cardColor],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.rotateLeft,
                  color: AppTheme.info,
                ),
                title: const Text('Mark as Incomplete'),
                onTap: () async {
                  final todoProvider = context.read<TodoProvider>();
                  final success = await todoProvider.markAsIncomplete(
                    todo.taskId,
                  );

                  if (bottomSheetContext.mounted) {
                    Navigator.of(bottomSheetContext).pop();
                  }

                  if (success && context.mounted) {
                    showAppSnack(
                      context,
                      'Task moved back to active tasks!',
                      icon: FontAwesomeIcons.rotateLeft,
                      color: AppTheme.info,
                    );
                  }
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.penToSquare,
                  color: AppTheme.warning,
                ),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showDialog(
                    context: context,
                    builder: (context) => EditTodoDialog(todo: todo),
                  );
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.trash,
                  color: AppTheme.accentColor,
                ),
                title: const Text('Delete Task'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  confirmAndDelete(context, todo, permanent: true);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOut).fadeIn(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    final body = Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final done = todoProvider.completedTodos;
        final panel = StatsPanel(stats: todoProvider.stats);

        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: done.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 520,
                                mainAxisExtent: 180,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                          itemCount: done.length,
                          itemBuilder: (context, i) =>
                              _buildCompletedTodoItem(context, done[i]),
                        ),
                ),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: panel),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            panel,
            const SizedBox(height: 20),
            if (done.isEmpty)
              SizedBox(height: 260, child: _buildEmptyState())
            else
              for (var i = 0; i < done.length; i++)
                _buildCompletedTodoItem(context, done[i])
                    .animate()
                    .fadeIn(delay: (50 * i).ms)
                    .slideX(begin: 0.2, end: 0),
          ],
        );
      },
    );

    final content = Column(
      children: [
        _buildAppBar(context, wide),
        Expanded(child: body),
      ],
    );

    if (embedded) return content;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool wide) {
    return Padding(
      padding: embedded && wide
          ? const EdgeInsets.fromLTRB(28, 24, 28, 18)
          : const EdgeInsets.all(20),
      child: Row(
        children: [
          if (!embedded) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const FaIcon(
                FontAwesomeIcons.arrowLeft,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          const Text(
            'Completed Tasks',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.circleCheck,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No completed tasks yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Complete tasks to see them here',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildCompletedTodoItem(BuildContext context, TodoModel todo) {
    final cardColor = AppTheme.cardColorAt(todo.colorIndex);
    final doneAt = todo.completedAt ?? todo.updatedAt ?? todo.createdAt;

    return GestureDetector(
      onTap: () => _showOptionsBottomSheet(context, todo),
      onLongPress: () => _showOptionsBottomSheet(context, todo),
      child: Container(
        margin: embedded || Breakpoints.isWide(context)
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 15),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 180,
          borderRadius: 20,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.2),
              cardColor.withValues(alpha: 0.1),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.3),
              cardColor.withValues(alpha: 0.1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppTheme.success,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 12,
                                color: AppTheme.success,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'DONE',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showOptionsBottomSheet(context, todo),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  todo.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.clock,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Completed: ${DateFormat('MMM dd, yyyy').format(doneAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      todo.taskId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
