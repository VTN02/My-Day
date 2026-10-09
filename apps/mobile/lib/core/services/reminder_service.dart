import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'notification_service.dart';

/// Reminder Notification Service for scheduling and displaying comprehensive task alerts.
/// Reminders display full task context (due time, priority, category, notes) as real
/// mobile OS system notifications outside the app, plus an in-app banner when active.
class ReminderService {
  final NotificationService _systemNotifications = NotificationService();

  ReminderService();

  String _getPriorityEmoji(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return '🔴 High Priority';
      case 'medium':
        return '🟡 Medium Priority';
      case 'low':
      default:
        return '🟢 Low Priority';
    }
  }

  /// Triggers a full task reminder:
  /// 1. Sends a real Android system notification to the status bar and lock screen (outside the app)
  /// 2. If the user is currently looking at the app, also displays an in-app banner.
  Future<void> triggerTaskReminder({
    BuildContext? context,
    required String title,
    required String priority,
    String? dueTime,
    String? category,
    String? description,
    VoidCallback? onComplete,
  }) async {
    // 1. Send native mobile OS notification outside the app
    await _systemNotifications.showTaskReminderNotification(
      id: title.hashCode.abs() % 100000,
      title: title,
      priority: priority,
      category: category,
      dueTime: dueTime,
      description: description,
    );

    // 2. If context is provided and mounted, also show in-app banner
    if (context != null && context.mounted) {
      showNotificationBanner(
        context: context,
        title: title,
        priority: priority,
        dueTime: dueTime,
        category: category,
        description: description,
        onComplete: onComplete,
      );
    }
  }

  /// Displays an actionable full-context reminder notification banner inside the app.
  void showNotificationBanner({
    required BuildContext context,
    required String title,
    required String priority,
    String? dueTime,
    String? category,
    String? description,
    VoidCallback? onComplete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityLabel = _getPriorityEmoji(priority);

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        elevation: 6,
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryIndigo.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.alarm_on_rounded,
            color: AppColors.primaryIndigo,
            size: 24,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '⏰ $title',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (priority.toLowerCase() == 'high'
                                ? AppColors.errorCoral
                                : AppColors.warningAmber)
                            .withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: priority.toLowerCase() == 'high'
                          ? AppColors.errorCoral
                          : AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${dueTime != null ? "Time: $dueTime • " : ""}${category != null ? "Category: $category • " : ""}${description != null && description.isNotEmpty ? description : "Scheduled reminder"}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          if (onComplete != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.successMint,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                onComplete();
              },
              child: const Text('Mark Done'),
            ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryIndigo,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  /// Sends a simulated high-priority reminder notification to the mobile system
  /// and displays the in-app banner.
  Future<void> sendTestReminder(BuildContext context) async {
    await triggerTaskReminder(
      context: context,
      title: 'Review Project Architecture & Releases',
      priority: 'high',
      dueTime: '2:30 PM',
      category: 'Work',
      description:
          'Double check SQLite migrations, JSON data exports, and offline sync tables before release.',
    );
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});
