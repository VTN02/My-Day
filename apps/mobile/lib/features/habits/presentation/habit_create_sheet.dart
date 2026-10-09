import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Shows an interactive bottom sheet to create a new habit.
Future<void> showHabitCreateSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _HabitCreateSheetContent(ref: ref),
  );
}

class _HabitCreateSheetContent extends StatefulWidget {
  final WidgetRef ref;

  const _HabitCreateSheetContent({required this.ref});

  @override
  State<_HabitCreateSheetContent> createState() => _HabitCreateSheetContentState();
}

class _HabitCreateSheetContentState extends State<_HabitCreateSheetContent> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Health';
  String _selectedColor = 'indigo';
  bool _isSaving = false;

  final _categories = const [
    ('Health', Icons.favorite_rounded),
    ('Fitness', Icons.fitness_center_rounded),
    ('Mind', Icons.self_improvement_rounded),
    ('Learning', Icons.menu_book_rounded),
    ('Productivity', Icons.bolt_rounded),
  ];

  final _colors = const [
    ('indigo', Color(0xFF4F46E5)),
    ('teal', Color(0xFF0D9488)),
    ('violet', Color(0xFF7C3AED)),
    ('amber', Color(0xFFF59E0B)),
    ('coral', Color(0xFFEF4444)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a habit title'),
          backgroundColor: AppColors.errorCoral,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.ref.read(habitsRepositoryProvider).createHabit(
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _selectedCategory,
        color: _selectedColor,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created habit "$title"'),
            backgroundColor: AppColors.successMint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create habit: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Daily Habit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Habit Title Input
            AppTextField(
              controller: _titleController,
              label: 'Habit Title',
              hint: 'e.g. Read 15 mins, Drink 2L water...',
              prefixIcon: const Icon(Icons.auto_awesome_rounded),
            ),
            const SizedBox(height: 14),

            // Habit Description Input
            AppTextField(
              controller: _descController,
              label: 'Description / Goal (Optional)',
              hint: 'e.g. Build focus before bed',
              prefixIcon: const Icon(Icons.notes_rounded),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.$2,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                      ),
                      const SizedBox(width: 6),
                      Text(cat.$1),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryIndigo,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat.$1);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color Selector
            Text(
              'Accent Theme',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final isSelected = _selectedColor == c.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.$2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.$2.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Submit Button
            PrimaryButton(
              text: 'Create Habit',
              isLoading: _isSaving,
              icon: Icons.add_task_rounded,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
