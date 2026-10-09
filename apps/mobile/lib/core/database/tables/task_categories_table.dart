import 'package:drift/drift.dart';

/// SQLite schema definition for Task Categories.
@DataClassName('TaskCategoryEntry')
class TaskCategoriesTable extends Table {
  @override
  String get tableName => 'task_categories';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();
  TextColumn get iconName => text().withDefault(const Constant('folder'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
