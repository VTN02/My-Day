import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// System-level Notification Service delivering rich notifications
/// outside the app (Android status bar, lock screen, heads-up banners)
/// just like Instagram, WhatsApp, and Facebook.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Channel IDs
  static const String taskChannelId = 'myday_tasks_channel';
  static const String taskChannelName = 'Task Reminders & Priorities';
  static const String taskChannelDescription =
      'Notifications for scheduled tasks, due dates, and high-priority reminders';

  static const String updateChannelId = 'myday_updates_channel';
  static const String updateChannelName = 'App Updates & Releases';
  static const String updateChannelDescription =
      'Notifications when a new version of MyDay is available to download';

  /// Initializes local notifications, Android channels, and requests permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Android settings with MyDay monogram launcher icon
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handled when user taps the notification from Android status bar/lock screen
      },
    );

    // Create high-importance Android Notification Channels
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // 1. Task Reminders Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          taskChannelId,
          taskChannelName,
          description: taskChannelDescription,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      // 2. App Updates Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          updateChannelId,
          updateChannelName,
          description: updateChannelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      // Request notification permission for Android 13+ (API 33+)
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    _isInitialized = true;
  }

  /// Sends an immediate system notification for a task reminder
  /// Displays full context in expandable BigText format so users don't need to open the app.
  Future<void> showTaskReminderNotification({
    int id = 100,
    required String title,
    required String priority,
    String? category,
    String? dueTime,
    String? description,
  }) async {
    await initialize();

    final priorityEmoji = _getPriorityEmoji(priority);
    final categoryLabel = category != null && category.isNotEmpty ? ' • $category' : '';
    final timeLabel = dueTime != null && dueTime.isNotEmpty ? 'Due: $dueTime' : 'Today';

    final summaryText = '$priorityEmoji$categoryLabel';
    final expandedBody = '$timeLabel\n${description != null && description.isNotEmpty ? description : "Scheduled Task"}';

    final androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4F46E5),
      styleInformation: BigTextStyleInformation(
        expandedBody,
        contentTitle: '⏰ $title ($summaryText)',
        summaryText: 'MyDay Task Reminder',
        htmlFormatContentTitle: false,
        htmlFormatBigText: false,
      ),
      ticker: 'Task Reminder: $title',
      visibility: NotificationVisibility.public, // Visible on phone lock screen
      category: AndroidNotificationCategory.reminder,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id,
      title: '⏰ $title',
      body: '$summaryText • $timeLabel',
      notificationDetails: notificationDetails,
      payload: 'task_$id',
    );
  }

  /// Sends a system notification alerting the user to an available APK update
  Future<void> showAppUpdateNotification({
    required String latestVersion,
    String? fileSize,
    List<String> releaseNotes = const [],
  }) async {
    await initialize();

    final notesText = releaseNotes.isNotEmpty
        ? 'What\'s new:\n${releaseNotes.map((n) => "• $n").join("\n")}'
        : 'A new version with performance improvements and bug fixes is ready to install.';

    final androidDetails = AndroidNotificationDetails(
      updateChannelId,
      updateChannelName,
      channelDescription: updateChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4F46E5),
      styleInformation: BigTextStyleInformation(
        notesText,
        contentTitle: '🚀 New MyDay Update (v$latestVersion)',
        summaryText: 'Tap to update without losing any data',
      ),
      ticker: 'New MyDay Update Available',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 999, // Distinct ID for app updates
      title: '🚀 New MyDay Update (v$latestVersion)',
      body: 'Tap to review new features and update (${fileSize ?? "28 MB"}).',
      notificationDetails: notificationDetails,
      payload: 'app_update',
    );
  }

  /// Schedules a future task reminder notification at the specified DateTime
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String priority,
    required DateTime scheduledDate,
    String? category,
    String? dueTime,
    String? description,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    final priorityEmoji = _getPriorityEmoji(priority);
    final summaryText = '$priorityEmoji${category != null ? " • $category" : ""}';
    final expandedBody = '${dueTime != null ? "Due at $dueTime\n" : ""}${description ?? "Scheduled Task"}';

    final androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4F46E5),
      styleInformation: BigTextStyleInformation(
        expandedBody,
        contentTitle: '⏰ $title ($summaryText)',
        summaryText: 'Scheduled Task Reminder',
      ),
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: '⏰ $title',
      body: summaryText,
      scheduledDate: tzDateTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels a notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

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
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
