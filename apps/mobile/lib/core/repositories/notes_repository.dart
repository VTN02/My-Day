import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

abstract class NotesRepository {
  Stream<List<NoteEntry>> watchAllNotes();
  Future<NoteEntry?> getNote(String id);
  Future<String> createNote({
    required String title,
    required String body,
    String category = 'General',
    bool isPinned = false,
  });
  Future<void> updateNote(NoteEntry note);
  Future<void> deleteNote(String id);

  Stream<List<NoteAttachmentEntry>> watchAttachmentsForNote(String noteId);
  Future<void> addAttachment({
    required String noteId,
    required String fileName,
    required String filePath,
    required String fileType,
    int? fileSizeBytes,
  });
  Future<void> deleteAttachment(String attachmentId);
}

class DriftNotesRepository implements NotesRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftNotesRepository(this._db);

  @override
  Stream<List<NoteEntry>> watchAllNotes() {
    final query = _db.select(_db.notesTable)
      ..orderBy([
        (n) => OrderingTerm(expression: n.isPinned, mode: OrderingMode.desc),
        (n) => OrderingTerm(expression: n.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Future<NoteEntry?> getNote(String id) {
    return (_db.select(
      _db.notesTable,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<String> createNote({
    required String title,
    required String body,
    String category = 'General',
    bool isPinned = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db
        .into(_db.notesTable)
        .insert(
          NotesTableCompanion.insert(
            id: id,
            title: title,
            body: body,
            category: Value(category),
            isPinned: Value(isPinned),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  @override
  Future<void> updateNote(NoteEntry note) async {
    await (_db.update(
      _db.notesTable,
    )..where((n) => n.id.equals(note.id))).write(
      NotesTableCompanion(
        title: Value(note.title),
        body: Value(note.body),
        category: Value(note.category),
        isPinned: Value(note.isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteNote(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteAttachmentsTable,
      )..where((a) => a.noteId.equals(id))).go();
      await (_db.delete(_db.notesTable)..where((n) => n.id.equals(id))).go();
    });
  }

  @override
  Stream<List<NoteAttachmentEntry>> watchAttachmentsForNote(String noteId) {
    return (_db.select(
      _db.noteAttachmentsTable,
    )..where((a) => a.noteId.equals(noteId))).watch();
  }

  @override
  Future<void> addAttachment({
    required String noteId,
    required String fileName,
    required String filePath,
    required String fileType,
    int? fileSizeBytes,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.noteAttachmentsTable)
        .insert(
          NoteAttachmentsTableCompanion.insert(
            id: id,
            noteId: noteId,
            fileName: fileName,
            filePath: filePath,
            fileType: fileType,
            fileSizeBytes: Value(fileSizeBytes ?? 0),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    await (_db.delete(
      _db.noteAttachmentsTable,
    )..where((a) => a.id.equals(attachmentId))).go();
  }
}
