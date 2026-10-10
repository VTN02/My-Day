import 'package:drift/drift.dart';

/// SQLite schema definition for Group Outings (MyDay Split).
@DataClassName('GroupOutingEntry')
class GroupOutingsTable extends Table {
  @override
  String get tableName => 'group_outings';

  TextColumn get id => text()(); // UUID v4
  TextColumn get organizerLocalId =>
      text()(); // References OutingMembersTable.id
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get outingDate => dateTime()();
  IntColumn get budgetMinor =>
      integer().withDefault(const Constant(0))(); // In minor units (cents)
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();
  TextColumn get status => text().withDefault(
    const Constant('active'),
  )(); // 'planned', 'active', 'completed', 'archived'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
