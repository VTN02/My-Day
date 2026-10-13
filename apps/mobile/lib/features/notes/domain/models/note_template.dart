/// Supported paper template types for note pages.
enum NoteTemplateType {
  blank,
  lined,
  grid,
  dotted;

  static NoteTemplateType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'lined':
        return NoteTemplateType.lined;
      case 'grid':
        return NoteTemplateType.grid;
      case 'dotted':
        return NoteTemplateType.dotted;
      case 'blank':
      default:
        return NoteTemplateType.blank;
    }
  }

  String get label {
    switch (this) {
      case NoteTemplateType.blank:
        return 'Blank Paper';
      case NoteTemplateType.lined:
        return 'Lined Paper';
      case NoteTemplateType.grid:
        return 'Grid Paper';
      case NoteTemplateType.dotted:
        return 'Dotted Paper';
    }
  }
}
