import 'package:deck_note/models/todo_model.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

/// Search box, priority / due-date chips and a sort menu. Reads and writes
/// the query on [TodoProvider].
class TodoFilterBar extends StatefulWidget {
  const TodoFilterBar({super.key});

  @override
  State<TodoFilterBar> createState() => _TodoFilterBarState();
}

class _TodoFilterBarState extends State<TodoFilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<TodoProvider>().query.text,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final q = provider.query;
    if (_controller.text != q.text) _controller.text = q.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('search-field'),
                controller: _controller,
                onChanged: (v) => provider.setQuery(q.copyWith(text: v)),
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                  suffixIcon: q.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () =>
                              provider.setQuery(q.copyWith(text: '')),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<TodoSort>(
              tooltip: 'Sort',
              initialValue: q.sort,
              color: AppTheme.cardColor,
              onSelected: (s) => provider.setQuery(q.copyWith(sort: s)),
              itemBuilder: (_) => [
                for (final s in TodoSort.values)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.arrowDownWideShort,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      q.sort.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (q.isFiltering)
                TextButton(
                  onPressed: provider.clearFilters,
                  child: const Text('Clear'),
                ),
              for (final p in Priority.values.reversed) ...[
                FilterChip(
                  key: Key('chip-priority-${p.name}'),
                  label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                  avatar: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppTheme.priorityColor(p),
                  ),
                  selected: q.priority == p,
                  onSelected: (on) => provider.setQuery(
                    on
                        ? q.copyWith(priority: p)
                        : q.copyWith(clearPriority: true),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 1,
                height: 22,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 8),
              for (final d in DueFilter.values.skip(1)) ...[
                FilterChip(
                  key: Key('chip-due-${d.name}'),
                  label: Text(d.label),
                  selected: q.due == d,
                  onSelected: (on) =>
                      provider.setQuery(q.copyWith(due: on ? d : DueFilter.any)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
