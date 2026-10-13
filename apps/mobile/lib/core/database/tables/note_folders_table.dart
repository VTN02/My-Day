import 'package:drift/drift.dart';

/// SQLite schema definition for Note Folders.
@DataClassName('NoteFolderEntry')
class NoteFoldersTable extends Table {
  @override
  String get tableName => 'note_folders';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get parentFolderId => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#1565C0'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
