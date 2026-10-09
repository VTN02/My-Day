import 'package:drift/drift.dart';

/// SQLite schema definition for Notes.
@DataClassName('NoteEntry')
class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get body => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Metadata table for Note Attachments stored in app-managed local storage.
@DataClassName('NoteAttachmentEntry')
class NoteAttachmentsTable extends Table {
  @override
  String get tableName => 'note_attachments';

  TextColumn get id => text()();
  TextColumn get noteId => text()(); // References NotesTable.id
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()(); // "image", "pdf", "doc"
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
