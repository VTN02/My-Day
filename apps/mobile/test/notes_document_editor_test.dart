import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/document_launcher_service.dart';
import 'package:mobile/features/notes/domain/models/drawing_stroke.dart';
import 'package:mobile/features/notes/domain/models/note_block.dart';

void main() {
  group('NoteBlock Document Model Tests', () {
    test(
      'Serializes and deserializes rich text and heading blocks accurately',
      () {
        final blocks = [
          const NoteBlock(
            id: 'h1_block',
            type: NoteBlockType.heading1,
            text: 'Project Architecture Plan',
          ),
          const NoteBlock(
            id: 'p_block',
            type: NoteBlockType.richText,
            text:
                'This is the main body paragraph with Word-like text formatting.',
          ),
          const NoteBlock(
            id: 'chk_block',
            type: NoteBlockType.checklist,
            text: 'Complete database verification',
            isChecked: true,
          ),
        ];

        final encoded = NoteBlock.encodeList(blocks);
        final decoded = NoteBlock.decodeList(encoded);

        expect(decoded.length, equals(3));
        expect(decoded[0].type, equals(NoteBlockType.heading1));
        expect(decoded[0].text, equals('Project Architecture Plan'));
        expect(decoded[1].type, equals(NoteBlockType.richText));
        expect(decoded[2].type, equals(NoteBlockType.checklist));
        expect(decoded[2].isChecked, isTrue);
      },
    );

    test(
      'Encodes and decodes ImageBlockMeta with resizing and alignment properties',
      () {
        const meta = ImageBlockMeta(
          filePath:
              '/data/user/0/com.myday.app/app_flutter/notes_attachments/note1/photo.jpg',
          widthPercent: 0.75,
          alignment: 'center',
          aspectRatio: 1.33,
          caption: 'Architecture Diagram',
        );

        final encoded = meta.encode();
        final decoded = ImageBlockMeta.tryDecode(encoded);

        expect(decoded, isNotNull);
        expect(decoded!.filePath, equals(meta.filePath));
        expect(decoded.widthPercent, equals(0.75));
        expect(decoded.alignment, equals('center'));
        expect(decoded.caption, equals('Architecture Diagram'));
      },
    );

    test('Encodes and decodes TextBoxMeta with coordinates and dimensions', () {
      const meta = TextBoxMeta(
        x: 0.15,
        y: 240.0,
        width: 250.0,
        height: 110.0,
        fontSize: 16.0,
        isBold: true,
        isItalic: false,
        colorHex: '#1565C0',
      );

      final encoded = meta.encode();
      final decoded = TextBoxMeta.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.x, equals(0.15));
      expect(decoded.y, equals(240.0));
      expect(decoded.width, equals(250.0));
      expect(decoded.isBold, isTrue);
      expect(decoded.colorHex, equals('#1565C0'));
    });

    test(
      'Gracefully handles legacy note blocks with plain paths or string metadata',
      () {
        final legacyMeta = ImageBlockMeta.tryDecode(
          '/storage/emulated/0/DCIM/Camera/IMG_01.jpg',
        );
        expect(legacyMeta, isNotNull);
        expect(
          legacyMeta!.filePath,
          equals('/storage/emulated/0/DCIM/Camera/IMG_01.jpg'),
        );
        expect(legacyMeta.widthPercent, equals(1.0));
        expect(legacyMeta.alignment, equals('center'));
      },
    );
  });

  group('DrawingStroke & Shapes Vector Tests', () {
    test(
      'Serializes strokes with new shapes (Line, Rectangle, Circle, Arrow)',
      () {
        final strokes = [
          const DrawingStroke(
            id: 'stroke_pen',
            points: [StrokePoint(x: 10, y: 15), StrokePoint(x: 20, y: 25)],
            tool: StrokeTool.pen,
            colorHex: '#1565C0',
            strokeWidth: 3.5,
          ),
          const DrawingStroke(
            id: 'stroke_rect',
            points: [StrokePoint(x: 50, y: 50), StrokePoint(x: 150, y: 120)],
            tool: StrokeTool.rectangle,
            colorHex: '#EF4444',
            strokeWidth: 2.0,
          ),
          const DrawingStroke(
            id: 'stroke_arrow',
            points: [StrokePoint(x: 10, y: 10), StrokePoint(x: 90, y: 90)],
            tool: StrokeTool.arrow,
            colorHex: '#10B981',
            strokeWidth: 2.5,
          ),
        ];

        final jsonString = DrawingStroke.encodeList(strokes);
        final decoded = DrawingStroke.decodeList(jsonString);

        expect(decoded.length, equals(3));
        expect(decoded[0].tool, equals(StrokeTool.pen));
        expect(decoded[1].tool, equals(StrokeTool.rectangle));
        expect(decoded[1].tool.isShape, isTrue);
        expect(decoded[2].tool, equals(StrokeTool.arrow));
        expect(decoded[2].tool.isShape, isTrue);
      },
    );

    test('Accurately handles opacity for highlighter and pencil strokes', () {
      const highlighter = DrawingStroke(
        id: 'h1',
        points: [StrokePoint(x: 0, y: 0)],
        tool: StrokeTool.highlighter,
        colorHex: '#FFEB3B',
        strokeWidth: 16.0,
      );

      const pencil = DrawingStroke(
        id: 'p1',
        points: [StrokePoint(x: 0, y: 0)],
        tool: StrokeTool.pencil,
        colorHex: '#000000',
        strokeWidth: 2.0,
      );

      expect(highlighter.color.a, closeTo(0.35, 0.05));
      expect(pencil.color.a, closeTo(0.70, 0.05));
    });
  });

  group('DocumentLauncherService MIME Type & Routing Tests', () {
    test('Resolves canonical MIME types for all supported document formats', () {
      expect(
        DocumentLauncherService.resolveMimeType('Contract.pdf'),
        equals('application/pdf'),
      );
      expect(
        DocumentLauncherService.resolveMimeType('Report.docx'),
        equals(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );
      expect(
        DocumentLauncherService.resolveMimeType('OldLetter.doc'),
        equals('application/msword'),
      );
      expect(
        DocumentLauncherService.resolveMimeType('Budget.xlsx'),
        equals(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      expect(
        DocumentLauncherService.resolveMimeType('readme.txt'),
        equals('text/plain'),
      );
      expect(
        DocumentLauncherService.resolveMimeType('screenshot.png'),
        equals('image/png'),
      );
      expect(
        DocumentLauncherService.resolveMimeType('photo.jpeg'),
        equals('image/jpeg'),
      );
    });

    test('Correctly classifies document types for viewer dispatch', () {
      expect(DocumentLauncherService.isPdf('document.pdf'), isTrue);
      expect(DocumentLauncherService.isPdf('document.docx'), isFalse);
      expect(DocumentLauncherService.isImage('photo.jpg'), isTrue);
      expect(DocumentLauncherService.isText('notes.txt'), isTrue);
      expect(DocumentLauncherService.isOfficeDoc('Report.docx'), isTrue);
      expect(DocumentLauncherService.isOfficeDoc('Data.xlsx'), isTrue);
      expect(DocumentLauncherService.isOfficeDoc('readme.txt'), isFalse);
    });
  });
}
