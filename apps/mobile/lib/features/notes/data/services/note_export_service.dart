import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../domain/models/note.dart';
import '../../domain/models/note_block.dart';

/// Professional Document Export Service for Notes (PDF and Share Sheet).
class NoteExportService {
  /// Generates a styled PDF document of the note and shares it via the Android share sheet.
  static Future<void> exportAndSharePdf(Note note) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('MMMM d, y • h:mm a');
    final formattedDate = dateFormat.format(note.updatedAt);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header: Category and Timestamp
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    note.category.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.blue800,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(
                  formattedDate,
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Note Title
            pw.Text(
              note.title.isEmpty ? 'Untitled Note' : note.title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Note Body Preview (if non-empty)
            if (note.body.isNotEmpty && note.blocks.isEmpty)
              pw.Paragraph(
                text: note.body,
                style: const pw.TextStyle(
                  fontSize: 11,
                  lineSpacing: 4,
                  color: PdfColors.grey800,
                ),
              ),

            // Structured Content Blocks (Text, Checklists)
            ...note.blocks.map((block) {
              if (block.type == NoteBlockType.checklist) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        margin: const pw.EdgeInsets.only(top: 2, right: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: block.isChecked
                                ? PdfColors.green700
                                : PdfColors.grey500,
                            width: 1.5,
                          ),
                          color: block.isChecked
                              ? PdfColors.green100
                              : PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: block.isChecked
                            ? pw.Center(
                                child: pw.Text(
                                  '✓',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          block.text,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: block.isChecked
                                ? PdfColors.grey500
                                : PdfColors.grey900,
                            decoration: block.isChecked
                                ? pw.TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(
                    block.text,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      lineSpacing: 4,
                      color: PdfColors.grey900,
                    ),
                  ),
                );
              }
            }),

            // Vector Drawing Strokes Preview (Rendered as vector lines in PDF)
            if (note.hasDrawings) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Handwritten Notes & Sketches',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 250,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.grey50,
                ),
                child: pw.CustomPaint(
                  size: const PdfPoint(500, 250),
                  painter: (PdfGraphics canvas, PdfPoint size) {
                    for (final stroke in note.drawingStrokes) {
                      if (stroke.points.length < 2) continue;
                      final hex = stroke.colorHex.replaceAll('#', '');
                      final intColor =
                          int.tryParse(hex, radix: 16) ?? 0xFF1565C0;
                      final pdfColor = PdfColor.fromInt(0xFF000000 | intColor);

                      canvas.setColor(pdfColor);
                      canvas.setLineWidth(stroke.strokeWidth * 0.7);

                      final p0 = stroke.points.first;
                      canvas.moveTo(p0.x, size.y - p0.y);

                      for (int i = 1; i < stroke.points.length; i++) {
                        final p = stroke.points[i];
                        canvas.lineTo(p.x, size.y - p.y);
                      }
                      canvas.strokePath();
                    }
                  },
                ),
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Exported from MyDay — Offline-First Productivity',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    // Save PDF bytes to temporary storage
    final outputDir = await getTemporaryDirectory();
    final sanitizedTitle = note.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${sanitizedTitle.isEmpty ? "MyDay_Note" : sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Share via Android native share sheet
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: note.title,
        text: 'Exported Note: ${note.title}',
      ),
    );
  }
}
