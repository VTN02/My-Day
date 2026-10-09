import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/task_card.dart';
import 'task_edit_sheet.dart';

/// Task Management Screen connected to Drift database.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Study',
    'Health',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTimeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _isTaskOverdue(TaskEntry task) {
    if (task.dueDate == null || task.isCompleted) return false;
    final now = DateTime.now();
    final endOfDueDay = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      23,
      59,
      59,
    );
    return now.isAfter(endOfDueDay);
  }

  Widget _buildQuickDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryIndigo
              : (isDark
                  ? AppColors.darkCardSurface
                  : AppColors.lightBackground),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryIndigo
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText),
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory =
        _selectedCategory == 'All' ? 'Work' : _selectedCategory;
    String selectedPriority = 'medium';
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surfaceColor =
            isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final secondaryTextColor =
            isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                    AppTextField(
                      label: 'Description (Optional)',
                      hint: 'Add any notes or context...',
                      controller: descriptionController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: [
                                  'Work',
                                  'Personal',
                                  'Study',
                                  'Health',
                                  'General',
                                ].map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedCategory = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: selectedPriority,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['low', 'medium', 'high'].map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.toUpperCase()),
                                  ),
                                ).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedPriority = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Schedule Section Header
                    const Text(
                      'Schedule Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick Date Preset Chips
                    Row(
                      children: [
                        _buildQuickDateChip(
                          label: 'Today',
                          isSelected: selectedDate != null &&
                              DateUtils.isSameDay(selectedDate, DateTime.now()),
                          onTap: () {
                            setModalState(() => selectedDate = DateTime.now());
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                          label: 'Tomorrow',
                          isSelected: selectedDate != null &&
                              DateUtils.isSameDay(
                                selectedDate,
                                DateTime.now().add(const Duration(days: 1)),
                              ),
                          onTap: () {
                            setModalState(
                              () => selectedDate = DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                          label: 'No Date',
                          isSelected: selectedDate == null,
                          onTap: () {
                            setModalState(() {
                              selectedDate = null;
                              selectedTime = null;
                            });
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Date & Time Interactive Pickers
                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate ?? now,
                                firstDate: now.subtract(const Duration(days: 365)),
                                lastDate: now.add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedDate != null
                                      ? AppColors.primaryIndigo.withValues(alpha: 0.5)
                                      : borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: selectedDate != null
                                        ? AppColors.primaryIndigo
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatDateLabel(selectedDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selectedDate != null
                                            ? (isDark
                                                ? AppColors.darkPrimaryText
                                                : AppColors.lightPrimaryText)
                                            : secondaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time Picker Button
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedTime != null
                                      ? AppColors.primaryIndigo.withValues(alpha: 0.5)
                                      : borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: selectedTime != null
                                        ? AppColors.primaryIndigo
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedTime != null
                                          ? _formatTimeLabel(selectedTime!)
                                          : 'Time (Optional)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selectedTime != null
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: selectedTime != null
                                            ? (isDark
                                                ? AppColors.darkPrimaryText
                                                : AppColors.lightPrimaryText)
                                            : secondaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selectedTime != null)
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() => selectedTime = null);
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Save Task',
                      isFullWidth: true,
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final desc = descriptionController.text.trim();

                        DateTime? finalDueDate;
                        if (selectedDate != null) {
                          finalDueDate = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime?.hour ?? 0,
                            selectedTime?.minute ?? 0,
                          );
                        }

                        String? finalDueTime;
                        if (selectedTime != null) {
                          finalDueTime = _formatTimeLabel(selectedTime!);
                        }

                        await ref.read(tasksRepositoryProvider).createTask(
                              title: title,
                              description: desc.isNotEmpty ? desc : null,
                              category: selectedCategory,
                              priority: selectedPriority,
                              dueDate: finalDueDate,
                              dueTime: finalDueTime,
                            );

                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'To-Dos & Habits',
              title: 'Tasks',
              subtitle: 'Organize and execute your priorities effortlessly',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  AppTextField(
                    hint: 'Search tasks...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: StatusChip(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          tasksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: LoadingState(message: 'Loading tasks from database...'),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading tasks: $err',
                  style: const TextStyle(color: AppColors.errorCoral),
                ),
              ),
            ),
            data: (tasks) {
              final query = _searchController.text.toLowerCase().trim();
              final filteredTasks = tasks.where((t) {
                final matchesCategory = _selectedCategory == 'All' ||
                    t.category.toLowerCase() == _selectedCategory.toLowerCase();
                final matchesSearch =
                    query.isEmpty || t.title.toLowerCase().contains(query);
                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredTasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No tasks found',
                    message: _selectedCategory == 'All'
                        ? 'Stay organized by adding your first task.'
                        : 'No tasks found in category "$_selectedCategory".',
                    actionLabel: 'Add Task',
                    onActionPressed: _showAddTaskSheet,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = filteredTasks[index];
                    return TaskCard(
                      key: ValueKey(task.id),
                      title: task.title,
                      category: task.category,
                      dueDate: _formatDateLabel(task.dueDate),
                      dueTime: task.dueTime,
                      priority: task.priority,
                      isCompleted: task.isCompleted,
                      isOverdue: _isTaskOverdue(task),
                      onTap: () => showTaskEditSheet(context, ref, task),
                      onToggle: (_) => ref
                          .read(tasksRepositoryProvider)
                          .toggleTaskCompletion(task.id),
                      onDelete: () =>
                          ref.read(tasksRepositoryProvider).deleteTask(task.id),
                    );
                  }, childCount: filteredTasks.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Task',
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
