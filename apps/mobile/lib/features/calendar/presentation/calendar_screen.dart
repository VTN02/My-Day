import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/task_card.dart';
import '../../tasks/presentation/task_edit_sheet.dart';

/// Monthly Calendar Screen connected to Drift database.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  final List<String> _weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  String _formatTimeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showDateDetailsSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(date);

        return Consumer(
          builder: (context, ref, _) {
            final tasksAsync = ref.watch(tasksForDateStreamProvider(date));

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Day Schedule & Quick Actions',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Add anything button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Task for this Day'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.smRadius,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddTaskSheet(date);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: tasksAsync.when(
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_available_outlined,
                                    size: 40,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black26,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No tasks scheduled for this day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: tasks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final task = tasks[idx];
                            return TaskCard(
                              key: ValueKey(task.id),
                              title: task.title,
                              category: task.category,
                              dueTime: task.dueTime,
                              priority: task.priority,
                              isCompleted: task.isCompleted,
                              onTap: () {
                                Navigator.pop(ctx);
                                showTaskEditSheet(context, ref, task);
                              },
                              onToggle: (_) => ref
                                  .read(tasksRepositoryProvider)
                                  .toggleTaskCompletion(task.id),
                              onDelete: () => ref
                                  .read(tasksRepositoryProvider)
                                  .deleteTask(task.id),
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
                      error: (err, _) =>
                          Center(child: Text('Error loading tasks: $err')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTaskSheet(DateTime initialDate) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Work';
    String selectedPriority = 'medium';
    DateTime selectedDate = initialDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surfaceColor = isDark
            ? AppColors.darkCardSurface
            : AppColors.lightCardSurface;
        final borderColor = isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder;
        final secondaryTextColor = isDark
            ? AppColors.darkSecondaryText
            : AppColors.lightSecondaryText;

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
                          'Schedule Task for ${DateFormat('MMM d').format(selectedDate)}',
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
                      hint: 'What do you want to schedule?',
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
                                items:
                                    [
                                          'Work',
                                          'Personal',
                                          'Study',
                                          'Health',
                                          'General',
                                        ]
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
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
                                items: ['low', 'medium', 'high']
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
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
                    const Text(
                      'Schedule Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: now.subtract(
                                  const Duration(days: 365),
                                ),
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
                                  color: AppColors.primaryIndigo.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: AppColors.primaryIndigo,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'EEE, MMM d',
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText,
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
                        // Time picker
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
                                      ? AppColors.primaryIndigo.withValues(
                                          alpha: 0.5,
                                        )
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
                                        setModalState(
                                          () => selectedTime = null,
                                        );
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

                        final finalDueDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime?.hour ?? 0,
                          selectedTime?.minute ?? 0,
                        );

                        String? finalDueTime;
                        if (selectedTime != null) {
                          finalDueTime = _formatTimeLabel(selectedTime!);
                        }

                        await ref
                            .read(tasksRepositoryProvider)
                            .createTask(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final selectedDate = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      _selectedDay,
    );

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            eyebrow: 'Schedule & Time',
            title: 'Calendar',
            subtitle: 'Tap any date to open details and add tasks',
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Month Navigation Inside the Calendar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 24,
                          ),
                          tooltip: 'Previous month',
                          onPressed: _previousMonth,
                        ),
                        Text(
                          '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 24,
                          ),
                          tooltip: 'Next month',
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Weekday Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekdays.map((day) {
                        return Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Rectangle Calendar Days Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.18, // Rectangle day cells
                          ),
                      itemCount: startingWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < startingWeekday) {
                          return const SizedBox.shrink();
                        }

                        final dayNumber = index - startingWeekday + 1;
                        final isSelected = dayNumber == _selectedDay;
                        final isToday =
                            dayNumber == DateTime.now().day &&
                            _currentMonth.month == DateTime.now().month &&
                            _currentMonth.year == DateTime.now().year;
                        final cellDate = DateTime(
                          _currentMonth.year,
                          _currentMonth.month,
                          dayNumber,
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = dayNumber;
                            });
                            _showDateDetailsSheet(cellDate);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryIndigo
                                  : (isToday
                                        ? (isDark
                                              ? AppColors.darkSoftIndigo
                                              : AppColors.lightSoftIndigo)
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.03,
                                                )
                                              : AppColors.lightBackground)),
                              borderRadius: AppRadius.smRadius,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryIndigo
                                    : (isToday
                                          ? AppColors.primaryIndigo
                                          : (isDark
                                                ? AppColors.darkBorder
                                                      .withValues(alpha: 0.6)
                                                : AppColors.lightBorder)),
                                width: isSelected || isToday ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.lightPrimaryText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title:
                    'Tasks for ${_monthName(_currentMonth.month)} $_selectedDay',
                subtitle: 'Scheduled events and to-dos for this day',
              ),
            ),
          ),
          ref
              .watch(tasksForDateStreamProvider(selectedDate))
              .when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Error loading tasks: $err',
                        style: const TextStyle(color: AppColors.errorCoral),
                      ),
                    ),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'No tasks scheduled',
                        message:
                            'Nothing scheduled for ${_monthName(_currentMonth.month)} $_selectedDay.',
                        actionLabel: 'Schedule Task',
                        onActionPressed: () => _showAddTaskSheet(selectedDate),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          key: ValueKey(task.id),
                          title: task.title,
                          category: task.category,
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
                      }, childCount: tasks.length),
                    ),
                  );
                },
              ),
        ],
      ),
    ),
  ],
),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Schedule Task',
        onPressed: () => _showAddTaskSheet(selectedDate),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
