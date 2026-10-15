import 'dart:convert';

enum NoteBlockType {
  richText,
  heading1,
  heading2,
  heading3,
  bullet,
  numbered,
  checklist,
  image,
  drawing,
  textBox,
  divider,
  attachment;

  static NoteBlockType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'heading1':
      case 'h1':
        return NoteBlockType.heading1;
      case 'heading2':
      case 'h2':
        return NoteBlockType.heading2;
      case 'heading3':
      case 'h3':
        return NoteBlockType.heading3;
      case 'bullet':
        return NoteBlockType.bullet;
      case 'numbered':
        return NoteBlockType.numbered;
      case 'checklist':
        return NoteBlockType.checklist;
      case 'image':
        return NoteBlockType.image;
      case 'drawing':
        return NoteBlockType.drawing;
      case 'textbox':
      case 'text_box':
        return NoteBlockType.textBox;
      case 'divider':
        return NoteBlockType.divider;
      case 'attachment':
        return NoteBlockType.attachment;
      case 'richtext':
      case 'paragraph':
      default:
        return NoteBlockType.richText;
    }
  }

  bool get isTextual =>
      this == NoteBlockType.richText ||
      this == NoteBlockType.heading1 ||
      this == NoteBlockType.heading2 ||
      this == NoteBlockType.heading3 ||
      this == NoteBlockType.bullet ||
      this == NoteBlockType.numbered;
}

/// Metadata model for Resizable Image blocks.
class ImageBlockMeta {
  final String filePath;
  final double widthPercent; // 0.25 to 1.0 (relative to page width)
  final String alignment; // 'left', 'center', 'right'
  final double? aspectRatio;
  final String? caption;

  const ImageBlockMeta({
    required this.filePath,
    this.widthPercent = 1.0,
    this.alignment = 'center',
    this.aspectRatio,
    this.caption,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'widthPercent': widthPercent,
    'alignment': alignment,
    if (aspectRatio != null) 'aspectRatio': aspectRatio,
    if (caption != null) 'caption': caption,
  };

  factory ImageBlockMeta.fromJson(Map<String, dynamic> json) {
    return ImageBlockMeta(
      filePath: json['filePath'] as String? ?? '',
      widthPercent: (json['widthPercent'] as num?)?.toDouble() ?? 1.0,
      alignment: json['alignment'] as String? ?? 'center',
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      caption: json['caption'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  static ImageBlockMeta? tryDecode(String? metaString) {
    if (metaString == null || metaString.trim().isEmpty) return null;
    try {
      final map = jsonDecode(metaString) as Map<String, dynamic>;
      return ImageBlockMeta.fromJson(map);
    } catch (_) {
      // In case meta was simply the raw file path in legacy notes
      return ImageBlockMeta(filePath: metaString);
    }
  }
}

/// Metadata model for Free-Positioned Text Boxes.
class TextBoxMeta {
  final double x; // Relative X coordinate (0.0 to 1.0 on page)
  final double y; // Absolute Y offset from top in dp
  final double width;
  final double height;
  final String? colorHex;
  final String? backgroundColorHex;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final String fontFamily;

  const TextBoxMeta({
    this.x = 0.05,
    this.y = 100.0,
    this.width = 220.0,
    this.height = 100.0,
    this.colorHex,
    this.backgroundColorHex,
    this.fontSize = 15.0,
    this.isBold = false,
    this.isItalic = false,
    this.fontFamily = 'Inter',
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    if (colorHex != null) 'colorHex': colorHex,
    if (backgroundColorHex != null) 'backgroundColorHex': backgroundColorHex,
    'fontSize': fontSize,
    'isBold': isBold,
    'isItalic': isItalic,
    'fontFamily': fontFamily,
  };

  factory TextBoxMeta.fromJson(Map<String, dynamic> json) {
    return TextBoxMeta(
      x: (json['x'] as num?)?.toDouble() ?? 0.05,
      y: (json['y'] as num?)?.toDouble() ?? 100.0,
      width: (json['width'] as num?)?.toDouble() ?? 220.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      colorHex: json['colorHex'] as String?,
      backgroundColorHex: json['backgroundColorHex'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 15.0,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
    );
  }

  String encode() => jsonEncode(toJson());

  static TextBoxMeta? tryDecode(String? metaString) {
    if (metaString == null || metaString.trim().isEmpty) return null;
    try {
      final map = jsonDecode(metaString) as Map<String, dynamic>;
      return TextBoxMeta.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

/// Metadata model for Rich Text Paragraph styles.
class TextBlockMeta {
  final String? colorHex;
  final String? highlightHex;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final double? fontSize;
  final String? fontFamily;
  final String alignment; // 'left', 'center', 'right', 'justify'

  const TextBlockMeta({
    this.colorHex,
    this.highlightHex,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.fontSize,
    this.fontFamily,
    this.alignment = 'left',
  });

  Map<String, dynamic> toJson() => {
    if (colorHex != null) 'colorHex': colorHex,
    if (highlightHex != null) 'highlightHex': highlightHex,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'isStrike': isStrike,
    if (fontSize != null) 'fontSize': fontSize,
    if (fontFamily != null) 'fontFamily': fontFamily,
    'alignment': alignment,
  };

  factory TextBlockMeta.fromJson(Map<String, dynamic> json) {
    return TextBlockMeta(
      colorHex: json['colorHex'] as String?,
      highlightHex: json['highlightHex'] as String?,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrike: json['isStrike'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontFamily: json['fontFamily'] as String?,
      alignment: json['alignment'] as String? ?? 'left',
    );
  }

  String encode() => jsonEncode(toJson());

  static TextBlockMeta? tryDecode(String? metaString) {
    if (metaString == null || metaString.trim().isEmpty) return null;
    try {
      final map = jsonDecode(metaString) as Map<String, dynamic>;
      return TextBlockMeta.fromJson(map);
    } catch (_) {
      return null;
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
