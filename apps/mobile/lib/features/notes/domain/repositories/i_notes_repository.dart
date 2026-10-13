import '../models/note.dart';
import '../models/note_folder_model.dart';

abstract class INotesRepository {
  Stream<List<Note>> watchAllActiveNotes();
  Stream<List<Note>> watchTrashedNotes();
  Stream<List<Note>> watchNotesByFolder(String? folderId);
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<void> togglePin(String id, bool isPinned);
  Future<void> moveToFolder(String id, String? folderId);
  Future<void> moveToTrash(String id);
  Future<void> restoreFromTrash(String id);
  Future<void> permanentlyDeleteNote(String id);
  Future<void> emptyTrash();
  Future<Note> duplicateNote(String id);
}

abstract class IFoldersRepository {
  Stream<List<NoteFolder>> watchFolders();
  Future<List<NoteFolder>> getAllFolders();
  Future<NoteFolder?> getFolderById(String id);
  Future<void> createFolder({
    required String name,
    String? parentFolderId,
    String colorHex = '#1565C0',
  });
  Future<void> renameFolder(String id, String newName);
  Future<void> deleteFolder(String id, {bool deleteNotes = false});
}
