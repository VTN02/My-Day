import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/section_header.dart';
import 'habit_create_sheet.dart';

/// Provider family for fetching dynamic streak count for a habit
final habitStreakFutureProvider =
    FutureProvider.family<int, String>((ref, habitId) async {
  // Re-fetch when today's habit logs change
  ref.watch(todayHabitLogsStreamProvider);
  return ref.watch(habitsRepositoryProvider).getStreakForHabit(habitId);
});

/// Interactive Daily Habits & Streaks Section for dashboard integration.
class DailyHabitsSection extends ConsumerWidget {
  const DailyHabitsSection({super.key});

  Color _resolveColor(String colorKey) {
    switch (colorKey.toLowerCase()) {
      case 'teal':
        return const Color(0xFF0D9488);
      case 'violet':
        return AppColors.secondaryViolet;
      case 'amber':
        return AppColors.warningAmber;
      case 'coral':
        return AppColors.errorCoral;
      case 'indigo':
      default:
        return AppColors.primaryIndigo;
    }
  }

  IconData _resolveCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'mind':
        return Icons.self_improvement_rounded;
      case 'learning':
        return Icons.menu_book_rounded;
      case 'productivity':
        return Icons.bolt_rounded;
      case 'health':
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitsAsync = ref.watch(activeHabitsStreamProvider);
    final logsAsync = ref.watch(todayHabitLogsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Daily Habits & Streaks',
          subtitle: 'Build consistency daily',
          trailing: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withValues(alpha: 0.12),
                borderRadius: AppRadius.smRadius,
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: AppColors.primaryIndigo,
              ),
            ),
            tooltip: 'Add Habit',
            onPressed: () => showHabitCreateSheet(context, ref),
          ),
        ),
        habitsAsync.when(
          data: (habits) {
            if (habits.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 36,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No habits set up yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track hydration, reading, workouts, or meditation daily.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Habit'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                      ),
                      onPressed: () => showHabitCreateSheet(context, ref),
                    ),
                  ],
                ),
              );
            }

            final completedHabitIds = (logsAsync.value ?? [])
                .where((l) => l.isCompleted)
                .map((l) => l.habitId)
                .toSet();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: habits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isCompletedToday = completedHabitIds.contains(habit.id);
                final habitColor = _resolveColor(habit.color);
                final streakAsync = ref.watch(habitStreakFutureProvider(habit.id));
                final streakCount = streakAsync.value ?? 0;

                return _HabitCard(
                  habit: habit,
                  isDark: isDark,
                  isCompletedToday: isCompletedToday,
                  habitColor: habitColor,
                  categoryIcon: _resolveCategoryIcon(habit.category),
                  streakCount: streakCount,
                  onToggle: () async {
                    await ref
                        .read(habitsRepositoryProvider)
                        .toggleHabitForDate(habit.id, DateTime.now());
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Habit?'),
                        content: Text(
                          'Are you sure you want to delete "${habit.title}" and its history?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.errorCoral),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(habitsRepositoryProvider).deleteHabit(habit.id);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Text('Error loading habits: $err'),
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitEntry habit;
  final bool isDark;
  final bool isCompletedToday;
  final Color habitColor;
  final IconData categoryIcon;
  final int streakCount;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.isDark,
    required this.isCompletedToday,
    required this.habitColor,
    required this.categoryIcon,
    required this.streakCount,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: isCompletedToday
              ? habitColor.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompletedToday ? 1.5 : 1,
        ),
        boxShadow: isCompletedToday
            ? [
                BoxShadow(
                  color: habitColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Completion Toggle Button
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? habitColor
                    : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompletedToday
                      ? habitColor
                      : (isDark ? Colors.white30 : Colors.black26),
                  width: 2,
                ),
              ),
              child: isCompletedToday
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Habit Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                    color: isCompletedToday
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                  ),
                ),
                if (habit.description != null && habit.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: habitColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            size: 11,
                            color: habitColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: habitColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: streakCount > 0
                            ? AppColors.warningAmber.withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.black12),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            streakCount > 0 ? '🔥' : '🌱',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            streakCount > 0 ? '$streakCount days' : 'New',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: streakCount > 0
                                  ? AppColors.warningAmber
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            onSelected: (val) {
              if (val == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.errorCoral, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Delete Habit',
                      style: TextStyle(color: AppColors.errorCoral, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
