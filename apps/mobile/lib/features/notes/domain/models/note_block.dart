import 'dart:convert';

enum NoteBlockType {
  richText,
  checklist,
  image,
  drawing,
  attachment;

  static NoteBlockType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'checklist':
        return NoteBlockType.checklist;
      case 'image':
        return NoteBlockType.image;
      case 'drawing':
        return NoteBlockType.drawing;
      case 'attachment':
        return NoteBlockType.attachment;
      case 'richtext':
      default:
        return NoteBlockType.richText;
    }
  }
}

/// A structured content block in a multi-format MyDay note document.
class NoteBlock {
  final String id;
  final NoteBlockType type;
  final String text; // For rich text and checklist item label
  final bool isChecked; // For checklist block
  final String? meta; // Path, style JSON, heading level, or attachment metadata

  const NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.isChecked = false,
    this.meta,
  });

  NoteBlock copyWith({
    String? id,
    NoteBlockType? type,
    String? text,
    bool? isChecked,
    String? meta,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'checked': isChecked,
    if (meta != null) 'meta': meta,
  };

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String,
      type: NoteBlockType.fromString(json['type'] as String? ?? 'richText'),
      text: json['text'] as String? ?? '',
      isChecked: json['checked'] as bool? ?? false,
      meta: json['meta'] as String?,
    );
  }

  static String encodeList(List<NoteBlock> blocks) {
    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }

  static List<NoteBlock> decodeList(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => NoteBlock.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
