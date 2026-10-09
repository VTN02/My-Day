import 'package:drift/drift.dart';

/// SQLite schema definition for Habits & Routines.
@DataClassName('HabitEntry')
class HabitsTable extends Table {
  @override
  String get tableName => 'habits';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('Health'))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get color => text().withDefault(const Constant('indigo'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Metadata table for daily habit completion logs.
@DataClassName('HabitLogEntry')
class HabitLogsTable extends Table {
  @override
  String get tableName => 'habit_logs';

  TextColumn get id => text()();
  TextColumn get habitId => text()(); // References HabitsTable.id
  DateTimeColumn get logDate =>
      dateTime()(); // Normalized to midnight YYYY-MM-DD
  BoolColumn get isCompleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
