import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../features/notes/domain/models/drawing_stroke.dart';
import '../../features/notes/domain/models/note.dart';
import '../../features/notes/domain/models/note_block.dart';
import '../../features/notes/domain/models/note_folder_model.dart';
import '../../features/notes/domain/models/note_template.dart';
import '../../features/notes/domain/repositories/i_notes_repository.dart';

class DriftNotesRepository implements INotesRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftNotesRepository(this._db);

  // Helper mapping NoteEntry -> Note domain model
  Note _mapEntryToNote(NoteEntry entry, {int attachmentCount = 0}) {
    return Note(
      id: entry.id,
      title: entry.title,
      body: entry.body,
      category: entry.category,
      folderId: entry.folderId,
      isPinned: entry.isPinned,
      isTrashed: entry.isTrashed,
      trashedAt: entry.trashedAt,
      templateType: NoteTemplateType.fromString(entry.templateType),
      blocks: NoteBlock.decodeList(entry.contentBlocksJson),
      drawingStrokes: DrawingStroke.decodeList(entry.drawingStrokesJson),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      attachmentCount: attachmentCount,
    );
  }

  // Helper mapping NoteFolderEntry -> NoteFolder domain model
  NoteFolder _mapEntryToFolder(NoteFolderEntry entry, {int noteCount = 0}) {
    return NoteFolder(
      id: entry.id,
      name: entry.name,
      parentFolderId: entry.parentFolderId,
      colorHex: entry.colorHex,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      noteCount: noteCount,
    );
  }

  // --- Reactive Streams ---

  @override
  Stream<List<Note>> watchAllActiveNotes() {
    final query = _db.select(_db.notesTable)
      ..where((n) => n.isTrashed.equals(false))
      ..orderBy([
        (n) => OrderingTerm(expression: n.isPinned, mode: OrderingMode.desc),
        (n) => OrderingTerm(expression: n.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((entries) {
      return entries.map((e) => _mapEntryToNote(e)).toList();
    });
  }

  @override
  Stream<List<Note>> watchTrashedNotes() {
    final query = _db.select(_db.notesTable)
      ..where((n) => n.isTrashed.equals(true))
      ..orderBy([
        (n) => OrderingTerm(expression: n.trashedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((entries) {
      return entries.map((e) => _mapEntryToNote(e)).toList();
    });
  }

  @override
  Stream<List<Note>> watchNotesByFolder(String? folderId) {
    final query = _db.select(_db.notesTable)
      ..where((n) => n.isTrashed.equals(false));

    if (folderId != null) {
      query.where((n) => n.folderId.equals(folderId));
    } else {
      query.where((n) => n.folderId.isNull());
    }

    query.orderBy([
      (n) => OrderingTerm(expression: n.isPinned, mode: OrderingMode.desc),
      (n) => OrderingTerm(expression: n.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((entries) {
      return entries.map((e) => _mapEntryToNote(e)).toList();
    });
  }

  // Backward compatibility alias for existing callers
  Stream<List<NoteEntry>> watchAllNotes() {
    final query = _db.select(_db.notesTable)
      ..where((n) => n.isTrashed.equals(false))
      ..orderBy([
        (n) => OrderingTerm(expression: n.isPinned, mode: OrderingMode.desc),
        (n) => OrderingTerm(expression: n.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  // --- CRUD Operations ---

  @override
  Future<List<Note>> getAllNotes() async {
    final query = _db.select(_db.notesTable)
      ..where((n) => n.isTrashed.equals(false))
      ..orderBy([
        (n) => OrderingTerm(expression: n.isPinned, mode: OrderingMode.desc),
        (n) => OrderingTerm(expression: n.updatedAt, mode: OrderingMode.desc),
      ]);
    final entries = await query.get();
    return entries.map((e) => _mapEntryToNote(e)).toList();
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final entry = await (_db.select(_db.notesTable)..where((n) => n.id.equals(id))).getSingleOrNull();
    if (entry == null) return null;

    final attachments = await (_db.select(_db.noteAttachmentsTable)..where((a) => a.noteId.equals(id))).get();
    return _mapEntryToNote(entry, attachmentCount: attachments.length);
  }

  Future<NoteEntry?> getNote(String id) {
    return (_db.select(_db.notesTable)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> saveNote(Note note) async {
    final now = DateTime.now();
    final blocksJson = NoteBlock.encodeList(note.blocks);
    final strokesJson = DrawingStroke.encodeList(note.drawingStrokes);

    // Extract plain body preview from blocks if empty
    String computedBody = note.body;
    if (computedBody.isEmpty && note.blocks.isNotEmpty) {
      computedBody = note.blocks
          .where((b) => b.text.trim().isNotEmpty)
          .map((b) => b.text.trim())
          .take(3)
          .join(' • ');
    }

    final companion = NotesTableCompanion(
      id: Value(note.id),
      title: Value(note.title.isEmpty ? 'Untitled Note' : note.title),
      body: Value(computedBody),
      category: Value(note.category),
      folderId: Value(note.folderId),
      isPinned: Value(note.isPinned),
      isTrashed: Value(note.isTrashed),
      trashedAt: Value(note.trashedAt),
      templateType: Value(note.templateType.name),
      contentBlocksJson: Value(blocksJson),
      drawingStrokesJson: Value(strokesJson),
      updatedAt: Value(now),
    );

    final existing = await getNoteById(note.id);
    if (existing == null) {
      await _db.into(_db.notesTable).insert(
            companion.copyWith(
              createdAt: Value(note.createdAt),
            ),
          );
    } else {
      await (_db.update(_db.notesTable)..where((n) => n.id.equals(note.id))).write(companion);
    }
  }

  @override
  Future<void> togglePin(String id, bool isPinned) async {
    await (_db.update(_db.notesTable)..where((n) => n.id.equals(id))).write(
      NotesTableCompanion(
        isPinned: Value(isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> moveToFolder(String id, String? folderId) async {
    await (_db.update(_db.notesTable)..where((n) => n.id.equals(id))).write(
      NotesTableCompanion(
        folderId: Value(folderId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> moveToTrash(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((n) => n.id.equals(id))).write(
      NotesTableCompanion(
        isTrashed: const Value(true),
        trashedAt: Value(now),
        isPinned: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    await (_db.update(_db.notesTable)..where((n) => n.id.equals(id))).write(
      NotesTableCompanion(
        isTrashed: const Value(false),
        trashedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteNote(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.noteAttachmentsTable)..where((a) => a.noteId.equals(id))).go();
      await (_db.delete(_db.notesTable)..where((n) => n.id.equals(id))).go();
    });
  }

  @override
  Future<void> emptyTrash() async {
    final trashed = await (_db.select(_db.notesTable)..where((n) => n.isTrashed.equals(true))).get();
    for (final note in trashed) {
      await permanentlyDeleteNote(note.id);
    }
  }

  @override
  Future<Note> duplicateNote(String id) async {
    final original = await getNoteById(id);
    if (original == null) throw Exception('Note not found');

    final newId = _uuid.v4();
    final now = DateTime.now();

    final duplicated = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    await saveNote(duplicated);
    return duplicated;
  }

  // --- Folder Management ---

  Stream<List<NoteFolder>> watchFolders() {
    return _db.select(_db.noteFoldersTable).watch().asyncMap((entries) async {
      final list = <NoteFolder>[];
      for (final e in entries) {
        final countQuery = _db.selectOnly(_db.notesTable)
          ..addColumns([_db.notesTable.id.count()])
          ..where(_db.notesTable.folderId.equals(e.id) & _db.notesTable.isTrashed.equals(false));
        final count = await countQuery.map((row) => row.read(_db.notesTable.id.count()) ?? 0).getSingle();
        list.add(_mapEntryToFolder(e, noteCount: count));
      }
      return list;
    });
  }

  Future<List<NoteFolder>> getAllFolders() async {
    final entries = await _db.select(_db.noteFoldersTable).get();
    return entries.map((e) => _mapEntryToFolder(e)).toList();
  }

  Future<void> createFolder({
    required String name,
    String? parentFolderId,
    String colorHex = '#1565C0',
  }) async {
    final now = DateTime.now();
    await _db.into(_db.noteFoldersTable).insert(
          NoteFoldersTableCompanion.insert(
            id: _uuid.v4(),
            name: name,
            parentFolderId: Value(parentFolderId),
            colorHex: Value(colorHex),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> renameFolder(String id, String newName) async {
    await (_db.update(_db.noteFoldersTable)..where((f) => f.id.equals(id))).write(
      NoteFoldersTableCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteFolder(String id, {bool deleteNotes = false}) async {
    await _db.transaction(() async {
      if (deleteNotes) {
        final notesInFolder = await (_db.select(_db.notesTable)..where((n) => n.folderId.equals(id))).get();
        for (final n in notesInFolder) {
          await moveToTrash(n.id);
        }
      } else {
        // Move notes to root (unorganized)
        await (_db.update(_db.notesTable)..where((n) => n.folderId.equals(id))).write(
          const NotesTableCompanion(folderId: Value(null)),
        );
      }
      await (_db.delete(_db.noteFoldersTable)..where((f) => f.id.equals(id))).go();
    });
  }

  // --- Attachments ---

  Stream<List<NoteAttachmentEntry>> watchAttachmentsForNote(String noteId) {
    return (_db.select(_db.noteAttachmentsTable)..where((a) => a.noteId.equals(noteId))).watch();
  }

  Future<void> addAttachment({
    required String noteId,
    required String fileName,
    required String filePath,
    required String fileType,
    int? fileSizeBytes,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.noteAttachmentsTable).insert(
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

  Future<void> deleteAttachment(String attachmentId) async {
    await (_db.delete(_db.noteAttachmentsTable)..where((a) => a.id.equals(attachmentId))).go();
  }
}
