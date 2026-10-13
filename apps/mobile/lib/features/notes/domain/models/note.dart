import 'drawing_stroke.dart';
import 'note_block.dart';
import 'note_template.dart';

/// Full domain representation of a MyDay Note.
class Note {
  final String id;
  final String title;
  final String body; // Plain text fallback/summary
  final String category;
  final String? folderId;
  final bool isPinned;
  final bool isTrashed;
  final DateTime? trashedAt;
  final NoteTemplateType templateType;
  final List<NoteBlock> blocks;
  final List<DrawingStroke> drawingStrokes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attachmentCount;

  const Note({
    required this.id,
    required this.title,
    this.body = '',
    this.category = 'General',
    this.folderId,
    this.isPinned = false,
    this.isTrashed = false,
    this.trashedAt,
    this.templateType = NoteTemplateType.blank,
    this.blocks = const [],
    this.drawingStrokes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.attachmentCount = 0,
  });

  bool get hasDrawings => drawingStrokes.isNotEmpty;
  bool get hasChecklists =>
      blocks.any((b) => b.type == NoteBlockType.checklist);
  bool get hasImages => blocks.any((b) => b.type == NoteBlockType.image);
  bool get hasAttachments => attachmentCount > 0;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? folderId,
    bool? isPinned,
    bool? isTrashed,
    DateTime? trashedAt,
    NoteTemplateType? templateType,
    List<NoteBlock>? blocks,
    List<DrawingStroke>? drawingStrokes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? attachmentCount,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      folderId: folderId ?? this.folderId,
      isPinned: isPinned ?? this.isPinned,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
      templateType: templateType ?? this.templateType,
      blocks: blocks ?? this.blocks,
      drawingStrokes: drawingStrokes ?? this.drawingStrokes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentCount: attachmentCount ?? this.attachmentCount,
    );
  }
}
