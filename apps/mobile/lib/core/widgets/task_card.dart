import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Interactive task list item card.
class TaskCard extends StatelessWidget {
  final String title;
  final String? category;
  final String? dueDate;
  final String? dueTime;
  final String priority; // 'low', 'medium', 'high'
  final bool isCompleted;
  final bool isOverdue;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.title,
    this.category,
    this.dueDate,
    this.dueTime,
    this.priority = 'medium',
    this.isCompleted = false,
    this.isOverdue = false,
    this.onToggle,
    this.onTap,
    this.onDelete,
  });

  Color _priorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.priorityHigh;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isOverdue && !isCompleted
              ? AppColors.errorCoral.withValues(alpha: 0.5)
              : borderColor,
        ),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isCompleted,
                    activeColor: AppColors.successMint,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(
                      color: isCompleted
                          ? AppColors.successMint
                          : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText),
                      width: 1.5,
                    ),
                    onChanged: onToggle,
                  ),
                ),
                const SizedBox(width: 8),

                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? (isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText)
                              : (isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSoftIndigo
                                    : AppColors.lightSoftIndigo,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Text(
                                category!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryIndigo,
                                ),
                              ),
                            ),
                          // Priority dot / badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityColor().withValues(alpha: 0.12),
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _priorityColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _priorityColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: isOverdue && !isCompleted
                                      ? AppColors.errorCoral
                                      : (isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.lightSecondaryText),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dueDate!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue && !isCompleted
                                        ? AppColors.errorCoral
                                        : (isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.lightSecondaryText),
                                    fontWeight: isOverdue && !isCompleted
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          if (dueTime != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 11,
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dueTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
