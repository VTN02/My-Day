/// Domain model representing a note folder with potential hierarchy.
class NoteFolder {
  final String id;
  final String name;
  final String? parentFolderId;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int noteCount;

  const NoteFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
    this.colorHex = '#1565C0',
    required this.createdAt,
    required this.updatedAt,
    this.noteCount = 0,
  });

  NoteFolder copyWith({
    String? id,
    String? name,
    String? parentFolderId,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? noteCount,
  }) {
    return NoteFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      noteCount: noteCount ?? this.noteCount,
    );
  }
}
