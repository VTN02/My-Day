import 'package:drift/drift.dart';

/// SQLite schema definition for Scheduled Task Reminders and Escalations.
@DataClassName('ScheduledReminderEntry')
class ScheduledRemindersTable extends Table {
  @override
  String get tableName => 'scheduled_reminders';

  TextColumn get id => text()();
  TextColumn get taskId => text()(); // References tasks.id
  IntColumn get attemptIndex => integer().withDefault(
    const Constant(0),
  )(); // 0 = base, 1 = follow-up 1, etc.
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get notificationId => integer()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, delivered, cancelled, snoozed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
