import 'package:deck_note/theme/app_theme.dart';
import 'package:deck_note/utils/todo_logic.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Progress ring plus a handful of counters. Used on the completed screen
/// (phones) and as the side panel on wide screens.
class StatsPanel extends StatelessWidget {
  final TodoStats stats;

  const StatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final percent = (stats.completionRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppTheme.space),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.09),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: stats.completionRate,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      key: const Key('completion-percent'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.total == 0
                          ? 'No tasks yet'
                          : '${stats.completed} of ${stats.total} tasks done',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _tile(
                    w,
                    FontAwesomeIcons.listCheck,
                    '${stats.active}',
                    'Active',
                    AppTheme.info,
                  ),
                  _tile(
                    w,
                    FontAwesomeIcons.circleCheck,
                    '${stats.completedThisWeek}',
                    'Done this week',
                    AppTheme.success,
                  ),
                  _tile(
                    w,
                    FontAwesomeIcons.fire,
                    '${stats.overdue}',
                    'Overdue',
                    AppTheme.danger,
                  ),
                  _tile(
                    w,
                    FontAwesomeIcons.calendarDay,
                    '${stats.dueToday}',
                    'Due today',
                    AppTheme.warning,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    double width,
    FaIconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
