import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../core/widgets/task_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../habits/presentation/daily_habits_section.dart';
import '../../tasks/presentation/task_edit_sheet.dart';
import '../../group_expenses/presentation/widgets/outing_gradient_card.dart';

/// Today Dashboard Screen connected to Drift database.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileAsync = ref.watch(userProfileStreamProvider);
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final accountsAsync = ref.watch(financialAccountsStreamProvider);

    final displayName = profileAsync.value?.displayName ?? 'MyDay User';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: todayTasksAsync.when(
              data: (tasks) {
                final totalTasks = tasks.length;
                final completedTasks = tasks.where((t) => t.isCompleted).length;
                final progressFactor = totalTasks == 0
                    ? 0.0
                    : completedTasks / totalTasks;
                final progressPercent = (progressFactor * 100).round();

                return GradientHeader(
                  eyebrow: "Today's Focus",
                  title: 'Good day, $displayName',
                  subtitle: '$totalTasks tasks scheduled for today',
                  trailing: Row(
                    children: [
                      IconButton(
                        tooltip: 'Profile',
                        padding: EdgeInsets.zero,
                        icon: UserAvatar(
                          avatarPath: profileAsync.value?.avatarPath,
                          displayName: displayName,
                          size: 30,
                        ),
                        onPressed: () => context.push('/profile'),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  bottomChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Completion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: Container(
                          height: 8,
                          color: Colors.white.withValues(alpha: 0.25),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressFactor.clamp(0.0, 1.0),
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => GradientHeader(
                eyebrow: "Today's Focus",
                title: 'Good day, $displayName',
                subtitle: 'Loading your day...',
              ),
              error: (error, stackTrace) => GradientHeader(
                eyebrow: "Today's Focus",
                title: 'Good day, $displayName',
                subtitle: 'Overview',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Metric Summary
                todayTasksAsync.when(
                  data: (tasks) {
                    final total = tasks.length;
                    final completed = tasks.where((t) => t.isCompleted).length;
                    final pending = total - completed;

                    return Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Tasks Done',
                            value: '$completed / $total',
                            subtitle: '$pending pending',
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.successMint,
                            iconBackgroundColor: isDark
                                ? AppColors.darkSoftMint
                                : AppColors.lightSoftMint,
                            onTap: () => context.go('/tasks'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: 'Daily Status',
                            value: pending == 0 && total > 0
                                ? 'All Done! 🎉'
                                : '$pending Left',
                            subtitle: 'Keep moving forward',
                            icon: Icons.flag_outlined,
                            iconColor: AppColors.primaryIndigo,
                            iconBackgroundColor: isDark
                                ? AppColors.darkSoftIndigo
                                : AppColors.lightSoftIndigo,
                            onTap: () => context.go('/tasks'),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Finance Snapshot
                SectionHeader(
                  title: 'Financial Balances',
                  actionLabel: 'View details',
                  onActionTap: () => context.go('/finance'),
                ),
                accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final cash = accounts
                        .cast<FinancialAccountEntry?>()
                        .firstWhere(
                          (a) => a?.id == 'account_cash',
                          orElse: () => accounts.first,
                        );
                    final card = accounts
                        .cast<FinancialAccountEntry?>()
                        .firstWhere(
                          (a) => a?.id == 'account_card',
                          orElse: () => accounts.last,
                        );
                    final cashBalance = cash?.currentBalanceCents ?? 0;
                    final cardBalance = card?.currentBalanceCents ?? 0;

                    return Row(
                      children: [
                        Expanded(
                          child: BalanceCard(
                            title: 'Cash Wallet',
                            amount: _formatCents(cashBalance),
                            subtitle: 'Liquid Cash',
                            icon: Icons.payments_outlined,
                            onTap: () => context.go('/finance'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BalanceCard(
                            title: 'Card Balance',
                            amount: _formatCents(cardBalance),
                            subtitle: 'Card / Bank',
                            icon: Icons.credit_card_outlined,
                            onTap: () => context.go('/finance'),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Quick Action Bar
                SectionHeader(title: 'Quick Actions'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatusChip(
                        label: 'Tasks',
                        icon: Icons.add_task_rounded,
                        isSelected: true,
                        onTap: () => context.go('/tasks'),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: 'Finance',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => context.go('/finance'),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: 'Notes',
                        icon: Icons.note_add_outlined,
                        onTap: () => context.go('/notes'),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: 'Split',
                        icon: Icons.groups_outlined,
                        onTap: () => context.push('/split'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // MyDay Split Outings Section
                const OutingGradientCard(),

                const SizedBox(height: 16),

                // Daily Habits & Streaks
                const DailyHabitsSection(),

                const SizedBox(height: 16),

                // Today's Scheduled Tasks
                SectionHeader(
                  title: "Today's Tasks",
                  subtitle: 'Real-time SQLite database tasks',
                  actionLabel: 'All tasks',
                  onActionTap: () => context.go('/tasks'),
                ),

                todayTasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return EmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No tasks scheduled for today',
                        message:
                            'Add a task to organize your day and track your progress.',
                        actionLabel: 'Add Task',
                        onActionPressed: () => context.go('/tasks'),
                      );
                    }

                    return Column(
                      children: tasks.map((task) {
                        return TaskCard(
                          key: ValueKey(task.id),
                          title: task.title,
                          category: task.category,
                          dueDate: 'Today',
                          dueTime: task.dueTime,
                          priority: task.priority,
                          isCompleted: task.isCompleted,
                          onTap: () => showTaskEditSheet(context, ref, task),
                          onToggle: (_) => ref
                              .read(tasksRepositoryProvider)
                              .toggleTaskCompletion(task.id),
                          onDelete: () => ref
                              .read(tasksRepositoryProvider)
                              .deleteTask(task.id),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Error loading today tasks: $err')),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Task',
        onPressed: () => context.go('/tasks'),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
