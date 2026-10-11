import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/home_wide.dart';
import 'package:deck_note/screens/profile_screen.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/breakpoints.dart';
import 'package:deck_note/utils/todo_actions.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:deck_note/widgets/add_todo_dialog.dart';
import 'package:deck_note/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:deck_note/widgets/task_deck.dart';
import 'completed_todos_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Which section the wide layout opens on (0 tasks, 1 completed, 2 profile).
  final int initialSection;

  const HomeScreen({super.key, this.initialSection = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeckNavigator _navigator = DeckNavigator();
  TodoQuery _lastQuery = const TodoQuery();
  late int _section = widget.initialSection;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final todoProvider = context.read<TodoProvider>();
      final user = authProvider.user;
      if (user != null) {
        todoProvider.listenToTodos(user.userId);
        todoProvider.listenToCompletedTodos(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _navigator.dispose();
    super.dispose();
  }

  Future<void> _refreshTodos() async {
    final authProvider = context.read<AuthProvider>();
    final todoProvider = context.read<TodoProvider>();

    if (authProvider.user != null) {
      todoProvider.listenToTodos(authProvider.user!.userId);
    }
  }

  bool _onSwipe(int previousIndex, CardSwiperDirection direction) {
    final todoProvider = context.read<TodoProvider>();
    final todos = todoProvider.visibleTodos;

    if (previousIndex >= todos.length) return false;

    final todo = todos[previousIndex];

    if (direction == CardSwiperDirection.right) {
      completeWithUndo(context, todo);
      // The finished card leaves the deck; the next one takes its place.
      _navigator.swiped(previousIndex);
      return true;
    } else if (direction == CardSwiperDirection.left) {
      // Ask first; the card only goes away once the delete went through.
      confirmAndDelete(context, todo);
      return false;
    }

    return false;
  }

  void _openAdd() {
    showDialog(context: context, builder: (context) => const AddTodoDialog());
  }

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isWide(context)) {
      return WideHome(
        section: _section,
        onSection: (i) => setState(() => _section = i),
        onAdd: _openAdd,
        navigator: _navigator,
        onSwipe: _onSwipe,
      );
    }
    return _buildPhone(context);
  }

  Widget _buildPhone(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshTodos,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.surfaceColor,
            child: Column(
              children: [
                _buildAppBar(),
                if (_showFilters)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TodoFilterBar(),
                  ),
                Expanded(
                  child: Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      if (todoProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.triangleExclamation,
                                size: 60,
                                color: AppTheme.danger.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Error loading tasks',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Text(
                                  todoProvider.error!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (todoProvider.todos.isEmpty) {
                        return _buildEmptyState();
                      }

                      final visible = todoProvider.visibleTodos;
                      if (visible.isEmpty) {
                        return _buildNoMatches(todoProvider);
                      }

                      if (todoProvider.query != _lastQuery) {
                        _lastQuery = todoProvider.query;
                        _navigator.swiped(0); // a new search starts at card 1
                      }

                      return Column(
                        children: [
                          DeckControls(navigator: _navigator, todos: visible),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: TaskDeck(
                                todos: visible,
                                navigator: _navigator,
                                onSwipe: _onSwipe,
                              ),
                            ),
                          ),
                          _buildSwipeInstructions(),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppTheme.primaryColor,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 20),
        label: const Text('Add Task'),
      ).animate().scale(delay: 300.ms).fadeIn(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DecXNote',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text(
                    'Hi, ${authProvider.user?.name ?? "User"}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Consumer<TodoProvider>(
                builder: (context, todoProvider, child) {
                  return IconButton(
                    key: const Key('toggle-filters'),
                    tooltip: 'Search and filter',
                    onPressed: () {
                      setState(() => _showFilters = !_showFilters);
                      if (!_showFilters) todoProvider.clearFilters();
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: _showFilters || todoProvider.query.isFiltering
                          ? AppTheme.primaryColor
                          : Colors.white,
                    ),
                  );
                },
              ),
              Consumer<TodoProvider>(
                builder: (context, todoProvider, child) {
                  final completedCount = todoProvider.completedTodos.length;
                  return Stack(
                    children: [
                      IconButton(
                        tooltip: 'Completed tasks',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CompletedTodosScreen(),
                            ),
                          );
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.clockRotateLeft,
                          color: Colors.white,
                        ),
                      ),
                      if (completedCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              completedCount > 9 ? '9+' : '$completedCount',
                              style: const TextStyle(
                                color: AppTheme.backgroundColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                icon: const FaIcon(FontAwesomeIcons.user, color: Colors.white),
              ),
            ],
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
            FontAwesomeIcons.clipboardList,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the button below to add your first task',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildNoMatches(TodoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: 60,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No matching tasks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInstruction(
            FontAwesomeIcons.arrowLeft,
            'Swipe left\nto delete',
            AppTheme.accentColor,
          ),
          _buildInstruction(
            FontAwesomeIcons.arrowRight,
            'Swipe right\nto complete',
            AppTheme.success,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInstruction(FaIconData icon, String text, Color color) {
    return Row(
      children: [
        FaIcon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
