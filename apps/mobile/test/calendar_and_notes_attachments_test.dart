import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/document_viewer/presentation/document_viewer_screen.dart';

void main() {
  group('DocumentViewerArgs & File Type Tests', () {
    test('Correctly identifies PDF arguments and external flags', () {
      const args = DocumentViewerArgs(
        filePath: '/storage/emulated/0/Download/Invoice_2026.pdf',
        fileName: 'Invoice_2026.pdf',
        mimeType: 'application/pdf',
        isExternal: true,
      );

      expect(args.fileName.endsWith('.pdf'), isTrue);
      expect(args.isExternal, isTrue);
      expect(args.mimeType, equals('application/pdf'));
    });

    test('Correctly formats and identifies images and office documents', () {
      const imageArgs = DocumentViewerArgs(
        filePath: '/data/user/0/com.myday.app/files/photo_123.jpg',
        fileName: 'photo_123.jpg',
        mimeType: 'image/jpeg',
      );

      const docxArgs = DocumentViewerArgs(
        filePath: '/storage/emulated/0/Download/Report.docx',
        fileName: 'Report.docx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );

      expect(imageArgs.fileName.toLowerCase().endsWith('.jpg'), isTrue);
      expect(docxArgs.fileName.toLowerCase().endsWith('.docx'), isTrue);
    });
  });

  group('Calendar Month Calculations & Task Distribution', () {
    test(
      'Calculates first day and days in month correctly across leap years',
      () {
        final febLeap = DateTime(2028, 2, 1);
        final daysInFebLeap = DateTime(febLeap.year, febLeap.month + 1, 0).day;
        expect(daysInFebLeap, equals(29));

        final febNormal = DateTime(2026, 2, 1);
        final daysInFebNormal = DateTime(
          febNormal.year,
          febNormal.month + 1,
          0,
        ).day;
        expect(daysInFebNormal, equals(28));

        final oct2026 = DateTime(2026, 10, 1);
        final daysInOct2026 = DateTime(oct2026.year, oct2026.month + 1, 0).day;
        expect(daysInOct2026, equals(31));
      },
    );

    test('Groups tasks by day number for calendar dot indicators', () {
      final sampleDueDates = [
        DateTime(2026, 10, 13, 9, 30),
        DateTime(2026, 10, 13, 14, 0),
        DateTime(2026, 10, 15, 11, 0),
        DateTime(2026, 10, 28, 16, 45),
      ];

      final Map<int, int> countByDay = {};
      for (final dt in sampleDueDates) {
        countByDay[dt.day] = (countByDay[dt.day] ?? 0) + 1;
      }

      expect(countByDay[13], equals(2));
      expect(countByDay[15], equals(1));
      expect(countByDay[28], equals(1));
      expect(countByDay[1], isNull);
    });
  });
}
