import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notes/domain/models/drawing_stroke.dart';
import 'package:mobile/features/notes/domain/models/note_block.dart';
import 'package:mobile/features/notes/domain/models/note_template.dart';

void main() {
  group('Smart Reminder Escalation Calculations', () {
    test('Notification IDs are deterministic and distinct per attempt', () {
      const taskId1 = 'task_abc_123';
      const taskId2 = 'task_xyz_789';

      final id1Attempt0 = ((taskId1.hashCode.abs() % 100000) * 10) + 0;
      final id1Attempt1 = ((taskId1.hashCode.abs() % 100000) * 10) + 1;
      final id1Attempt2 = ((taskId1.hashCode.abs() % 100000) * 10) + 2;

      final id2Attempt0 = ((taskId2.hashCode.abs() % 100000) * 10) + 0;

      expect(id1Attempt0, isNot(equals(id1Attempt1)));
      expect(id1Attempt1, isNot(equals(id1Attempt2)));
      expect(id1Attempt0, isNot(equals(id2Attempt0)));
    });

    test('Escalation follow-up intervals compute properly', () {
      final baseDue = DateTime(2026, 10, 15, 8, 0); // 8:00 AM
      const intervalMinutes = 10;
      const maxRepeats = 3;

      final followUps = <DateTime>[];
      for (int i = 1; i <= maxRepeats; i++) {
        followUps.add(baseDue.add(Duration(minutes: intervalMinutes * i)));
      }

      expect(followUps.length, equals(3));
      expect(followUps[0], equals(DateTime(2026, 10, 15, 8, 10)));
      expect(followUps[1], equals(DateTime(2026, 10, 15, 8, 20)));
      expect(followUps[2], equals(DateTime(2026, 10, 15, 8, 30)));
    });
  });

  group('Notes Vector Stroke & Block Serialization', () {
    test('DrawingStroke encodes and decodes accurately', () {
      final strokes = [
        const DrawingStroke(
          id: 'stroke_1',
          points: [
            StrokePoint(x: 10.5, y: 20.0, pressure: 0.8),
            StrokePoint(x: 15.0, y: 25.5, pressure: 1.0),
          ],
          tool: StrokeTool.pen,
          colorHex: '#1565C0',
          strokeWidth: 3.5,
        ),
      ];

      final encoded = DrawingStroke.encodeList(strokes);
      expect(encoded, contains('stroke_1'));
      expect(encoded, contains('#1565C0'));

      final decoded = DrawingStroke.decodeList(encoded);
      expect(decoded.length, equals(1));
      expect(decoded.first.id, equals('stroke_1'));
      expect(decoded.first.points.length, equals(2));
      expect(decoded.first.points.first.x, equals(10.5));
      expect(decoded.first.points.first.pressure, equals(0.8));
    });

    test('NoteBlock checklist and text serialization', () {
      final blocks = [
        const NoteBlock(
          id: 'block_text_1',
          type: NoteBlockType.richText,
          text: 'Project Architecture Review',
        ),
        const NoteBlock(
          id: 'block_check_1',
          type: NoteBlockType.checklist,
          text: 'Verify Drift v3 migrations',
          isChecked: true,
        ),
      ];

      final jsonStr = NoteBlock.encodeList(blocks);
      final restored = NoteBlock.decodeList(jsonStr);

      expect(restored.length, equals(2));
      expect(restored.first.type, equals(NoteBlockType.richText));
      expect(restored.last.type, equals(NoteBlockType.checklist));
      expect(restored.last.isChecked, isTrue);
    });

    test('NoteTemplateType parses from string correctly', () {
      expect(
        NoteTemplateType.fromString('lined'),
        equals(NoteTemplateType.lined),
      );
      expect(
        NoteTemplateType.fromString('grid'),
        equals(NoteTemplateType.grid),
      );
      expect(
        NoteTemplateType.fromString('dotted'),
        equals(NoteTemplateType.dotted),
      );
      expect(
        NoteTemplateType.fromString('blank'),
        equals(NoteTemplateType.blank),
      );
      expect(
        NoteTemplateType.fromString('unknown'),
        equals(NoteTemplateType.blank),
      );
    });
  });
}
