import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../core/widgets/task_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';

/// Today Dashboard Screen Foundation.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: "Today's Focus",
              title: 'Good morning, Alex',
              subtitle: 'Wednesday, October 8 • 4 tasks planned',
              trailing: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => context.push('/profile'),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
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
                        '75%',
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
                        widthFactor: 0.75,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Metric Summary
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Tasks Done',
                        value: '3 / 4',
                        subtitle: '1 pending',
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.successMint,
                        iconBackgroundColor: isDark
                            ? AppColors.darkSoftMint
                            : AppColors.lightSoftMint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'Today Spent',
                        value: 'Rs. 1,450',
                        subtitle: 'Food & Transit',
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppColors.errorCoral,
                        iconBackgroundColor: isDark
                            ? AppColors.darkSoftCoral
                            : AppColors.lightSoftCoral,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Finance Snapshot
                SectionHeader(
                  title: 'Financial Balances',
                  actionLabel: 'View details',
                  onActionTap: () => context.go('/finance'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: BalanceCard(
                        title: 'Cash Wallet',
                        amount: 'Rs. 8,500',
                        subtitle: 'Liquid cash',
                        icon: Icons.payments_outlined,
                        onTap: () => context.go('/finance'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BalanceCard(
                        title: 'Card Balance',
                        amount: 'Rs. 45,200',
                        subtitle: 'Commercial Bank',
                        icon: Icons.credit_card_outlined,
                        onTap: () => context.go('/finance'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick Action Bar
                SectionHeader(title: 'Quick Actions'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatusChip(
                        label: 'Add Task',
                        icon: Icons.add_task_rounded,
                        isSelected: true,
                        onTap: () => context.go('/tasks'),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: 'Record Expense',
                        icon: Icons.remove_circle_outline,
                        onTap: () => context.go('/finance'),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: 'New Note',
                        icon: Icons.note_add_outlined,
                        onTap: () => context.go('/notes'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Today's Scheduled Tasks
                SectionHeader(
                  title: "Today's Tasks",
                  subtitle: 'Focus on what matters most today',
                  actionLabel: 'All tasks',
                  onActionTap: () => context.go('/tasks'),
                ),

                TaskCard(
                  title: 'Review production monorepo architecture',
                  category: 'Work',
                  dueDate: 'Today',
                  dueTime: '10:00 AM',
                  priority: 'high',
                  isCompleted: true,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Prepare grocery list for the weekend',
                  category: 'Personal',
                  dueDate: 'Today',
                  dueTime: '06:30 PM',
                  priority: 'medium',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Study Flutter Riverpod 3.0 documentation',
                  category: 'Study',
                  dueDate: 'Today',
                  dueTime: '08:00 PM',
                  priority: 'low',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => context.go('/tasks'),
      ),
    );
  }
}
