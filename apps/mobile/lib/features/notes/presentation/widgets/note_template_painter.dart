import 'package:flutter/material.dart';
import '../../domain/models/note_template.dart';

/// CustomPainter rendering paper backgrounds: Blank, Lined, Grid, or Dotted.
class NoteTemplatePainter extends CustomPainter {
  final NoteTemplateType templateType;
  final bool isDark;

  const NoteTemplatePainter({required this.templateType, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (templateType == NoteTemplateType.blank) return;

    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    switch (templateType) {
      case NoteTemplateType.lined:
        const lineHeight = 32.0;
        for (double y = lineHeight; y < size.height; y += lineHeight) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
        break;

      case NoteTemplateType.grid:
        const gridSize = 24.0;
        for (double y = gridSize; y < size.height; y += gridSize) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
        for (double x = gridSize; x < size.width; x += gridSize) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
        break;

      case NoteTemplateType.dotted:
        const dotSpacing = 24.0;
        final dotPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        for (double y = dotSpacing; y < size.height; y += dotSpacing) {
          for (double x = dotSpacing; x < size.width; x += dotSpacing) {
            canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
          }
        }
        break;

      case NoteTemplateType.blank:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant NoteTemplatePainter oldDelegate) {
    return oldDelegate.templateType != templateType ||
        oldDelegate.isDark != isDark;
  }
}
