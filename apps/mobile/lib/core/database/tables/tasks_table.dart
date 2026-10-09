import 'package:drift/drift.dart';

/// SQLite schema definition for Tasks.
@DataClassName('TaskEntry')
class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))(); // low, medium, high
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get dueTime => text().nullable()(); // "HH:mm"
  TextColumn get reminder => text().withDefault(
    const Constant('none'),
  )(); // none, once, hourly, custom
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
