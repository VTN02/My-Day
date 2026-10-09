import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Shows an interactive bottom sheet to edit an existing task.
Future<void> showTaskEditSheet(
  BuildContext context,
  WidgetRef ref,
  TaskEntry task,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TaskEditSheetContent(task: task, ref: ref),
  );
}

class _TaskEditSheetContent extends StatefulWidget {
  final TaskEntry task;
  final WidgetRef ref;

  const _TaskEditSheetContent({
    required this.task,
    required this.ref,
  });

  @override
  State<_TaskEditSheetContent> createState() => _TaskEditSheetContentState();
}

class _TaskEditSheetContentState extends State<_TaskEditSheetContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedPriority;
  late DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _selectedCategory = widget.task.category;
    _selectedPriority = widget.task.priority.toLowerCase();
    _selectedDate = widget.task.dueDate;
    _isCompleted = widget.task.isCompleted;

    if (widget.task.dueTime != null && widget.task.dueTime!.isNotEmpty) {
      _selectedTime = _parseTimeOfDay(widget.task.dueTime!);
    } else if (widget.task.dueDate != null) {
      final d = widget.task.dueDate!;
      if (d.hour != 0 || d.minute != 0) {
        _selectedTime = TimeOfDay(hour: d.hour, minute: d.minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.trim().split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (parts.length >= 3) {
          final isPm = parts[2].toUpperCase() == 'PM';
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
    return DateFormat('EEE, MMM d, y').format(date);
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

  Widget _buildPriorityChip({
    required String priority,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedPriority == priority.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              priority,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText)
                    : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
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
                  'Edit Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorCoral),
                      tooltip: 'Delete Task',
                      onPressed: () async {
                        await widget.ref
                            .read(tasksRepositoryProvider)
                            .deleteTask(widget.task.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Task Title',
              hint: 'Task headline...',
              controller: _titleController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Description (Optional)',
              hint: 'Add notes or context...',
              controller: _descriptionController,
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
                        initialValue: _selectedCategory,
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
                            child: Text(c, style: const TextStyle(fontSize: 13)),
                          ),
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPriorityChip(
                            priority: 'Low',
                            color: AppColors.priorityLow,
                            isDark: isDark,
                          ),
                          _buildPriorityChip(
                            priority: 'Med',
                            color: AppColors.priorityMedium,
                            isDark: isDark,
                          ),
                          _buildPriorityChip(
                            priority: 'High',
                            color: AppColors.priorityHigh,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Due Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickDateChip(
                    label: 'Today',
                    isSelected: _selectedDate != null &&
                        _selectedDate!.year == today.year &&
                        _selectedDate!.month == today.month &&
                        _selectedDate!.day == today.day,
                    onTap: () => setState(() => _selectedDate = today),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickDateChip(
                    label: 'Tomorrow',
                    isSelected: _selectedDate != null &&
                        _selectedDate!.year == tomorrow.year &&
                        _selectedDate!.month == tomorrow.month &&
                        _selectedDate!.day == tomorrow.day,
                    onTap: () => setState(() => _selectedDate = tomorrow),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickDateChip(
                    label: 'No Date',
                    isSelected: _selectedDate == null,
                    onTap: () => setState(() {
                      _selectedDate = null;
                      _selectedTime = null;
                    }),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? today,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.event_outlined, size: 16),
                    label: Text(
                      _selectedDate != null
                          ? _formatDateLabel(_selectedDate)
                          : 'Pick Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: _selectedDate != null
                            ? AppColors.primaryIndigo
                            : borderColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due Time (Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedTime != null
                          ? _formatTimeLabel(_selectedTime!)
                          : 'No specific time set',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _selectedTime != null
                            ? AppColors.primaryIndigo
                            : secondaryTextColor,
                        fontWeight: _selectedTime != null
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear Time',
                        onPressed: () => setState(() => _selectedTime = null),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ??
                              const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                            _selectedDate ??= today;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time_outlined, size: 16),
                      label: Text(
                        _selectedTime != null ? 'Change' : 'Pick Time',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Mark as Completed',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              value: _isCompleted,
              activeColor: AppColors.successMint,
              onChanged: (val) {
                if (val != null) setState(() => _isCompleted = val);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Save Changes',
                    icon: Icons.check,
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) return;

                      final desc = _descriptionController.text.trim();

                      DateTime? finalDueDate;
                      if (_selectedDate != null) {
                        finalDueDate = DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          _selectedTime?.hour ?? 0,
                          _selectedTime?.minute ?? 0,
                        );
                      }

                      String? finalDueTime;
                      if (_selectedTime != null) {
                        finalDueTime = _formatTimeLabel(_selectedTime!);
                      }

                      final updated = widget.task.copyWith(
                        title: title,
                        description: Value(desc.isNotEmpty ? desc : null),
                        category: _selectedCategory,
                        priority: _selectedPriority,
                        dueDate: Value(finalDueDate),
                        dueTime: Value(finalDueTime),
                        isCompleted: _isCompleted,
                        updatedAt: DateTime.now(),
                      );

                      await widget.ref
                          .read(tasksRepositoryProvider)
                          .updateTask(updated);

                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
