import 'package:drift/drift.dart';

/// SQLite schema definition for Outing Members.
@DataClassName('OutingMemberEntry')
class OutingMembersTable extends Table {
  @override
  String get tableName => 'outing_members';

  TextColumn get id => text()(); // UUID v4
  TextColumn get outingId => text()(); // References GroupOutingsTable.id
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get linkedUserId => text().nullable()(); // Future MyDay ID sync
  BoolColumn get isOrganizer => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
