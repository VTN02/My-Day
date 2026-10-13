import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../domain/models/drawing_stroke.dart';
import '../../domain/models/note_template.dart';
import 'note_template_painter.dart';

/// Interactive vector handwriting and drawing canvas widget with S-Pen & stylus support.
class DrawingCanvasWidget extends StatefulWidget {
  final List<DrawingStroke> initialStrokes;
  final NoteTemplateType templateType;
  final ValueChanged<List<DrawingStroke>> onStrokesChanged;
  final bool isInteractive;
  final double? height;

  const DrawingCanvasWidget({
    super.key,
    required this.initialStrokes,
    this.templateType = NoteTemplateType.blank,
    required this.onStrokesChanged,
    this.isInteractive = true,
    this.height,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  final Uuid _uuid = const Uuid();
  late List<DrawingStroke> _strokes;
  final List<List<DrawingStroke>> _undoStack = [];
  final List<List<DrawingStroke>> _redoStack = [];

  // Active Tool Settings
  StrokeTool _activeTool = StrokeTool.pen;
  String _activeColorHex = '#1565C0';
  double _strokeWidth = 3.5;

  // In-progress stroke
  List<StrokePoint> _currentPoints = [];

  final List<String> _palette = [
    '#1565C0', // Ocean Blue
    '#0288D1', // Cyan
    '#10B981', // Mint Green
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#0F172A', // Dark Slate
    '#FFFFFF', // White
  ];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
  }

  @override
  void didUpdateWidget(covariant DrawingCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStrokes != widget.initialStrokes &&
        _currentPoints.isEmpty) {
      _strokes = List.from(widget.initialStrokes);
    }
  }

  void _recordHistory() {
    _undoStack.add(List.from(_strokes));
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_strokes));
    setState(() {
      _strokes = _undoStack.removeLast();
    });
    widget.onStrokesChanged(_strokes);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_strokes));
    setState(() {
      _strokes = _redoStack.removeLast();
    });
    widget.onStrokesChanged(_strokes);
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Drawing Canvas?'),
        content: const Text(
          'All drawing strokes on this canvas will be permanently erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorCoral),
            onPressed: () {
              Navigator.of(ctx).pop();
              _recordHistory();
              setState(() {
                _strokes.clear();
              });
              widget.onStrokesChanged(_strokes);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isInteractive) return;
    _recordHistory();
    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0 ? event.pressure : 1.0,
    );

    if (_activeTool == StrokeTool.eraser) {
      _eraseAt(event.localPosition);
    } else {
      setState(() {
        _currentPoints = [point];
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.isInteractive) return;
    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0 ? event.pressure : 1.0,
    );

    if (_activeTool == StrokeTool.eraser) {
      _eraseAt(event.localPosition);
    } else {
      setState(() {
        _currentPoints.add(point);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.isInteractive || _currentPoints.isEmpty) return;

    final newStroke = DrawingStroke(
      id: _uuid.v4(),
      points: List.from(_currentPoints),
      tool: _activeTool,
      colorHex: _activeColorHex,
      strokeWidth: _activeTool == StrokeTool.highlighter
          ? _strokeWidth * 4.0
          : _strokeWidth,
    );

    setState(() {
      _strokes.add(newStroke);
      _currentPoints = [];
    });

    widget.onStrokesChanged(_strokes);
  }

  void _eraseAt(Offset pos) {
    const eraseRadius = 18.0;
    final originalCount = _strokes.length;

    _strokes.removeWhere((stroke) {
      return stroke.points.any((p) {
        final dist = (Offset(p.x, p.y) - pos).distance;
        return dist <= eraseRadius;
      });
    });

    if (_strokes.length != originalCount) {
      setState(() {});
      widget.onStrokesChanged(_strokes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isInteractive) _buildToolbar(isDark),
        Container(
          height: widget.height ?? 380,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1527) : const Color(0xFFFBFDFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Template Background (Lined, Grid, Dotted)
              CustomPaint(
                painter: NoteTemplatePainter(
                  templateType: widget.templateType,
                  isDark: isDark,
                ),
              ),
              // 2. Vector Stroke Canvas
              Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                child: CustomPaint(
                  painter: _StrokesPainter(
                    strokes: _strokes,
                    inProgressPoints: _currentPoints,
                    inProgressTool: _activeTool,
                    inProgressColor: _activeColorHex,
                    inProgressWidth: _activeTool == StrokeTool.highlighter
                        ? _strokeWidth * 4.0
                        : _strokeWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Tool: Pen
              _buildToolButton(
                icon: Icons.edit_rounded,
                label: 'Pen',
                isSelected: _activeTool == StrokeTool.pen,
                onTap: () => setState(() => _activeTool = StrokeTool.pen),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              // Tool: Highlighter
              _buildToolButton(
                icon: Icons.border_color_rounded,
                label: 'Highlighter',
                isSelected: _activeTool == StrokeTool.highlighter,
                onTap: () => setState(() => _activeTool = StrokeTool.highlighter),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              // Tool: Eraser
              _buildToolButton(
                icon: Icons.auto_fix_normal_rounded,
                label: 'Eraser',
                isSelected: _activeTool == StrokeTool.eraser,
                onTap: () => setState(() => _activeTool = StrokeTool.eraser),
                isDark: isDark,
              ),
              const Spacer(),
              // Undo
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                onPressed: _undoStack.isNotEmpty ? _undo : null,
                tooltip: 'Undo',
                visualDensity: VisualDensity.compact,
              ),
              // Redo
              IconButton(
                icon: const Icon(Icons.redo_rounded, size: 20),
                onPressed: _redoStack.isNotEmpty ? _redo : null,
                tooltip: 'Redo',
                visualDensity: VisualDensity.compact,
              ),
              // Clear
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: _strokes.isNotEmpty ? _clearCanvas : null,
                tooltip: 'Clear Canvas',
                color: AppColors.errorCoral,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (_activeTool != StrokeTool.eraser) ...[
            const Divider(height: 12),
            Row(
              children: [
                // Stroke Width Chips
                ...[2.0, 4.0, 7.0].map((w) {
                  final isSel = (_strokeWidth - w).abs() < 0.5;
                  return GestureDetector(
                    onTap: () => setState(() => _strokeWidth = w),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryIndigo.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primaryIndigo
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: w,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black87,
                            borderRadius: BorderRadius.circular(w / 2),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                // Color Palette
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _palette.map((hex) {
                        final isSel = _activeColorHex == hex;
                        final color = Color(
                          int.parse(hex.replaceFirst('#', '0xFF')),
                        );
                        return GestureDetector(
                          onTap: () => setState(() => _activeColorHex = hex),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.black12,
                                width: isSel ? 2.5 : 1.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryIndigo.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryIndigo : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryIndigo
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryIndigo
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter that renders vector strokes smoothly using Bézier curve interpolation.
class _StrokesPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<StrokePoint> inProgressPoints;
  final StrokeTool inProgressTool;
  final String inProgressColor;
  final double inProgressWidth;

  _StrokesPainter({
    required this.strokes,
    required this.inProgressPoints,
    required this.inProgressTool,
    required this.inProgressColor,
    required this.inProgressWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint completed strokes
    for (final stroke in strokes) {
      _paintStroke(
        canvas: canvas,
        points: stroke.points,
        tool: stroke.tool,
        colorHex: stroke.colorHex,
        strokeWidth: stroke.strokeWidth,
      );
    }

    // 2. Paint current in-progress stroke
    if (inProgressPoints.length > 1) {
      _paintStroke(
        canvas: canvas,
        points: inProgressPoints,
        tool: inProgressTool,
        colorHex: inProgressColor,
        strokeWidth: inProgressWidth,
      );
    }
  }

  void _paintStroke({
    required Canvas canvas,
    required List<StrokePoint> points,
    required StrokeTool tool,
    required String colorHex,
    required double strokeWidth,
  }) {
    if (points.isEmpty) return;

    final hex = colorHex.replaceAll('#', '');
    final intColor = int.tryParse(hex, radix: 16) ?? 0xFF000000;
    final baseColor = hex.length == 6 ? Color(0xFF000000 | intColor) : Color(intColor);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == StrokeTool.highlighter) {
      paint.color = baseColor.withValues(alpha: 0.35);
      paint.strokeWidth = strokeWidth;
    } else {
      paint.color = baseColor;
      paint.strokeWidth = strokeWidth;
    }

    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points.first.x, points.first.y),
        strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      // Quadratic Bézier midpoint smoothing
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }

    path.lineTo(points.last.x, points.last.y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}
