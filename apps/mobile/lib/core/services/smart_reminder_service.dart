import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';
import 'notification_service.dart';
import 'tune_manager_service.dart';

/// Service managing Smart Reminders: multi-attempt escalation scheduling,
/// cancellation upon task completion, snoozing, and local SQLite tracking.
class SmartReminderService {
  final AppDatabase _db;
  final NotificationService _notificationService;
  final TuneManagerService _tuneManagerService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

  SmartReminderService(
    this._db,
    this._notificationService,
    this._tuneManagerService,
  );

  /// Computes a deterministic integer notification ID for a task and attempt index.
  /// Guarantees zero collision across tasks while keeping attempt IDs in a predictable range.
  int getNotificationId(String taskId, int attemptIndex) {
    final base = (taskId.hashCode.abs() % 100000) * 10;
    return base + attemptIndex;
  }

  /// Schedules a base reminder and subsequent follow-up escalations if enabled on the task.
  Future<void> scheduleTaskWithEscalation(TaskEntry task) async {
    await _notificationService.initialize();

    // 1. Cancel any previously scheduled reminders for this task first
    await cancelTaskReminders(task.id);

    // If task is completed or has no due date, do not schedule
    if (task.isCompleted || task.dueDate == null) return;

    DateTime scheduledBase = task.dueDate!;
    if (task.dueTime != null && task.dueTime!.isNotEmpty) {
      final parsed = _parseTimeOfDay(task.dueTime!);
      if (parsed != null) {
        scheduledBase = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
          parsed.$1,
          parsed.$2,
        );
      }
    }

    final now = DateTime.now();

    // Determine the dedicated notification channel for the selected tune
    final channelId =
        await _tuneManagerService.ensureNotificationChannelForTune(
      tuneId: task.selectedTuneId,
      plugin: _notificationsPlugin,
    );

    // 2. Schedule Base Reminder (Attempt 0)
    if (scheduledBase.isAfter(now)) {
      final baseNotifId = getNotificationId(task.id, 0);
      await _scheduleLocalNotification(
        id: baseNotifId,
        title: '⏰ ${task.title}',
        body: 'Due now • Priority: ${task.priority.toUpperCase()}',
        scheduledDate: scheduledBase,
        channelId: channelId,
        taskId: task.id,
        attemptIndex: 0,
      );

      await _recordScheduledReminder(
        taskId: task.id,
        attemptIndex: 0,
        scheduledAt: scheduledBase,
        notificationId: baseNotifId,
      );
    }

    // 3. Schedule Follow-up Escalations if enabled
    if (task.followUpEnabled && task.maxRepeats > 0) {
      final delayMinutes = task.followUpDelayMinutes > 0
          ? task.followUpDelayMinutes
          : 10;
      final maxAttempts = task.maxRepeats.clamp(1, 3);

      for (int i = 1; i <= maxAttempts; i++) {
        final escalationTime = scheduledBase.add(
          Duration(minutes: delayMinutes * i),
        );

        if (escalationTime.isAfter(now)) {
          final notifId = getNotificationId(task.id, i);
          final attemptLabel = i == 1 ? '1st Follow-up' : '$i${i == 2 ? "nd" : "rd"} Follow-up';

          await _scheduleLocalNotification(
            id: notifId,
            title: '⚠️ Incomplete: ${task.title} ($attemptLabel)',
            body: 'Task remains incomplete. Due at ${task.dueTime ?? "Today"}.',
            scheduledDate: escalationTime,
            channelId: channelId,
            taskId: task.id,
            attemptIndex: i,
          );

          await _recordScheduledReminder(
            taskId: task.id,
            attemptIndex: i,
            scheduledAt: escalationTime,
            notificationId: notifId,
          );
        }
      }
    }
  }

  /// Cancels all pending notifications and records for a given task ID.
  Future<void> cancelTaskReminders(String taskId) async {
    // 1. Fetch pending reminders from SQLite
    final pendingReminders = await (_db.select(_db.scheduledRemindersTable)
          ..where((r) => r.taskId.equals(taskId) & r.status.equals('pending')))
        .get();

    for (final rem in pendingReminders) {
      await _notificationService.cancelNotification(rem.notificationId);
    }

    // Also cancel potential IDs 0 through 4 deterministically
    for (int i = 0; i <= 4; i++) {
      final notifId = getNotificationId(taskId, i);
      await _notificationService.cancelNotification(notifId);
    }

    // 2. Mark database records as cancelled
    await (_db.update(_db.scheduledRemindersTable)
          ..where((r) => r.taskId.equals(taskId) & r.status.equals('pending')))
        .write(
      const ScheduledRemindersTableCompanion(
        status: drift.Value('cancelled'),
      ),
    );
  }

  /// Snoozes a task reminder by rescheduling it [minutes] from now.
  Future<void> snoozeTask(String taskId, {int minutes = 10}) async {
    await cancelTaskReminders(taskId);

    final task = await (_db.select(_db.tasksTable)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();

    if (task == null || task.isCompleted) return;

    final snoozedTime = DateTime.now().add(Duration(minutes: minutes));
    final notifId = getNotificationId(taskId, 0);

    final channelId =
        await _tuneManagerService.ensureNotificationChannelForTune(
      tuneId: task.selectedTuneId,
      plugin: _notificationsPlugin,
    );

    await _scheduleLocalNotification(
      id: notifId,
      title: '⏰ Snoozed: ${task.title}',
      body: 'Snoozed for $minutes mins • Priority: ${task.priority.toUpperCase()}',
      scheduledDate: snoozedTime,
      channelId: channelId,
      taskId: taskId,
      attemptIndex: 0,
    );

    await _recordScheduledReminder(
      taskId: taskId,
      attemptIndex: 0,
      scheduledAt: snoozedTime,
      notificationId: notifId,
    );
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String taskId,
    required int attemptIndex,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Task Reminders',
      channelDescription: 'Smart reminders for scheduled tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1565C0),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'MyDay Task Reminder',
      ),
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$taskId',
    );
  }

  Future<void> _recordScheduledReminder({
    required String taskId,
    required int attemptIndex,
    required DateTime scheduledAt,
    required int notificationId,
  }) async {
    await _db.into(_db.scheduledRemindersTable).insert(
          ScheduledRemindersTableCompanion.insert(
            id: _uuid.v4(),
            taskId: taskId,
            attemptIndex: drift.Value(attemptIndex),
            scheduledAt: scheduledAt,
            notificationId: notificationId,
            status: const drift.Value('pending'),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
  }

  (int, int)? _parseTimeOfDay(String timeStr) {
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
        return (hour, minute);
      }
    } catch (_) {}
    return null;
  }
}

final smartReminderServiceProvider = Provider<SmartReminderService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notifs = ref.watch(notificationServiceProvider);
  final tunes = ref.watch(tuneManagerServiceProvider);
  return SmartReminderService(db, notifs, tunes);
});
