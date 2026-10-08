import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/task_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Task Management Screen Foundation.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Study',
    'Health',
  ];

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Task Title',
                hint: 'What do you need to accomplish?',
                controller: titleController,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Due Date',
                      hint: 'YYYY-MM-DD',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Priority',
                      hint: 'Medium',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.flag_outlined, size: 18),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Save Task',
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task added to schedule')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Organize & Execute',
              title: 'Tasks & To-Dos',
              subtitle: '6 active tasks across 3 categories',
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Search bar preview
                  AppTextField(
                    hint: 'Search tasks, tags or priorities...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  const SizedBox(height: 12),
                  // Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: StatusChip(
                            label: category,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TaskCard(
                  title: 'Setup Drift local SQLite models and tables',
                  category: 'Work',
                  dueDate: 'Today',
                  dueTime: '02:00 PM',
                  priority: 'high',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Implement GoRouter navigation shell',
                  category: 'Work',
                  dueDate: 'Today',
                  dueTime: '04:00 PM',
                  priority: 'high',
                  isCompleted: true,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: '30-minute afternoon cardio session',
                  category: 'Health',
                  dueDate: 'Today',
                  dueTime: '05:30 PM',
                  priority: 'medium',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Grocery shopping: Fruits, milk, oats',
                  category: 'Personal',
                  dueDate: 'Tomorrow',
                  dueTime: '09:00 AM',
                  priority: 'low',
                  isCompleted: false,
                  onToggle: (v) {},
                ),
                TaskCard(
                  title: 'Read chapter 3 of Clean Code',
                  category: 'Study',
                  dueDate: 'Tomorrow',
                  dueTime: '08:00 PM',
                  priority: 'medium',
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
        onPressed: _showAddTaskSheet,
      ),
    );
  }
}
