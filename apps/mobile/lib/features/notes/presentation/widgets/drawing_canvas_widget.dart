import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../domain/models/drawing_stroke.dart';
import '../../domain/models/note_template.dart';
import 'note_template_painter.dart';

/// Interactive vector handwriting and drawing canvas widget with S-Pen & stylus support,
/// expandable canvas height, advanced tools (Pen, Pencil, Highlighter, Brush, Eraser),
/// shapes (Line, Rectangle, Circle, Arrow), and vector rendering.
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
  late double _canvasHeight;

  // In-progress stroke
  List<StrokePoint> _currentPoints = [];

  final List<String> _palette = [
    '#1565C0', // Ocean Blue
    '#0288D1', // Cyan
    '#10B981', // Mint Green
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#0F172A', // Dark Slate
    '#475569', // Slate Grey
    '#FFFFFF', // White
  ];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
    _canvasHeight = widget.height ?? 460.0;
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
          'All strokes on this canvas will be permanently erased.',
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

  void _expandCanvas(double additionalHeight) {
    setState(() {
      _canvasHeight = (_canvasHeight + additionalHeight).clamp(300.0, 5000.0);
    });
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
        if (_activeTool.isShape) {
          // For shapes, we keep start point and update current end point
          if (_currentPoints.length > 1) {
            _currentPoints[1] = point;
          } else {
            _currentPoints.add(point);
          }
        } else {
          _currentPoints.add(point);
        }
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
          : (_activeTool == StrokeTool.pencil
                ? _strokeWidth * 0.8
                : _strokeWidth),
    );

    setState(() {
      _strokes.add(newStroke);
      _currentPoints = [];
    });

    widget.onStrokesChanged(_strokes);
  }

  void _eraseAt(Offset pos) {
    const eraseRadius = 24.0;
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
          height: _canvasHeight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1527) : const Color(0xFFFBFDFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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
                  painter: StrokesPainter(
                    strokes: _strokes,
                    inProgressPoints: _currentPoints,
                    inProgressTool: _activeTool,
                    inProgressColor: _activeColorHex,
                    inProgressWidth: _activeTool == StrokeTool.highlighter
                        ? _strokeWidth * 4.0
                        : (_activeTool == StrokeTool.pencil
                              ? _strokeWidth * 0.8
                              : _strokeWidth),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.isInteractive) ...[
          const SizedBox(height: 8),
          // Canvas expand controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Canvas Height: ${_canvasHeight.toInt()}px',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      '+ 300px Space',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _expandCanvas(300),
                  ),
                  if (_canvasHeight > 460) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                      ),
                      tooltip: 'Shrink Canvas',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _expandCanvas(-300),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Drawing & Shape Tools
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolButton(
                  icon: Icons.edit_rounded,
                  label: 'Pen',
                  isSelected: _activeTool == StrokeTool.pen,
                  onTap: () => setState(() => _activeTool = StrokeTool.pen),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.create_rounded,
                  label: 'Pencil',
                  isSelected: _activeTool == StrokeTool.pencil,
                  onTap: () => setState(() => _activeTool = StrokeTool.pencil),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.brush_rounded,
                  label: 'Brush',
                  isSelected: _activeTool == StrokeTool.brush,
                  onTap: () => setState(() => _activeTool = StrokeTool.brush),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.border_color_rounded,
                  label: 'Highlighter',
                  isSelected: _activeTool == StrokeTool.highlighter,
                  onTap: () =>
                      setState(() => _activeTool = StrokeTool.highlighter),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.auto_fix_normal_rounded,
                  label: 'Eraser',
                  isSelected: _activeTool == StrokeTool.eraser,
                  onTap: () => setState(() => _activeTool = StrokeTool.eraser),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 22,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 6),
                // Shape Tools
                _buildToolButton(
                  icon: Icons.horizontal_rule_rounded,
                  label: 'Line',
                  isSelected: _activeTool == StrokeTool.line,
                  onTap: () => setState(() => _activeTool = StrokeTool.line),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.crop_square_rounded,
                  label: 'Box',
                  isSelected: _activeTool == StrokeTool.rectangle,
                  onTap: () =>
                      setState(() => _activeTool = StrokeTool.rectangle),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.circle_outlined,
                  label: 'Circle',
                  isSelected: _activeTool == StrokeTool.circle,
                  onTap: () => setState(() => _activeTool = StrokeTool.circle),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildToolButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Arrow',
                  isSelected: _activeTool == StrokeTool.arrow,
                  onTap: () => setState(() => _activeTool = StrokeTool.arrow),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 22,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 6),
                // Undo / Redo / Clear
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  onPressed: _undoStack.isNotEmpty ? _undo : null,
                  tooltip: 'Undo',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, size: 20),
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                  tooltip: 'Redo',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: AppColors.errorCoral,
                  ),
                  onPressed: _strokes.isNotEmpty ? _clearCanvas : null,
                  tooltip: 'Clear All',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Stroke Width & Color Palette
          Row(
            children: [
              // Stroke Width Presets
              ...[2.0, 4.0, 7.0, 12.0].map((w) {
                final isSel = (_strokeWidth - w).abs() < 1.0;
                return GestureDetector(
                  onTap: () => setState(() => _strokeWidth = w),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel
                            ? AppColors.primaryIndigo
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSel ? 2.0 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: w.clamp(3.0, 14.0),
                        height: w.clamp(3.0, 14.0),
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
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.black26,
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryIndigo.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
                fontSize: 11,
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

/// CustomPainter that renders vector strokes and geometric shapes with Bézier curve smoothing.
class StrokesPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<StrokePoint> inProgressPoints;
  final StrokeTool inProgressTool;
  final String inProgressColor;
  final double inProgressWidth;

  StrokesPainter({
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
    if (inProgressPoints.isNotEmpty) {
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
    final baseColor = hex.length == 6
        ? Color(0xFF000000 | intColor)
        : Color(intColor);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == StrokeTool.highlighter) {
      paint.color = baseColor.withValues(alpha: 0.35);
      paint.strokeWidth = strokeWidth;
    } else if (tool == StrokeTool.pencil) {
      paint.color = baseColor.withValues(alpha: 0.70);
      paint.strokeWidth = strokeWidth;
    } else if (tool == StrokeTool.brush) {
      paint.color = baseColor.withValues(alpha: 0.85);
      paint.strokeWidth = strokeWidth * 1.5;
    } else {
      paint.color = baseColor;
      paint.strokeWidth = strokeWidth;
    }

    // Single tap dot
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points.first.x, points.first.y),
        strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final p0 = points.first;
    final pLast = points.last;

    // --- Shape rendering ---
    if (tool == StrokeTool.line) {
      canvas.drawLine(Offset(p0.x, p0.y), Offset(pLast.x, pLast.y), paint);
      return;
    }

    if (tool == StrokeTool.rectangle) {
      final rect = Rect.fromPoints(
        Offset(p0.x, p0.y),
        Offset(pLast.x, pLast.y),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );
      return;
    }

    if (tool == StrokeTool.circle) {
      final rect = Rect.fromPoints(
        Offset(p0.x, p0.y),
        Offset(pLast.x, pLast.y),
      );
      canvas.drawOval(rect, paint);
      return;
    }

    if (tool == StrokeTool.arrow) {
      final start = Offset(p0.x, p0.y);
      final end = Offset(pLast.x, pLast.y);
      canvas.drawLine(start, end, paint);

      // Arrow head calculations
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowLength = 16.0;
      const arrowAngle = math.pi / 6;

      final arrowP1 = Offset(
        end.dx - arrowLength * math.cos(angle - arrowAngle),
        end.dy - arrowLength * math.sin(angle - arrowAngle),
      );
      final arrowP2 = Offset(
        end.dx - arrowLength * math.cos(angle + arrowAngle),
        end.dy - arrowLength * math.sin(angle + arrowAngle),
      );

      canvas.drawLine(end, arrowP1, paint);
      canvas.drawLine(end, arrowP2, paint);
      return;
    }

    // --- Smooth Freehand / Handwriting Stroke rendering ---
    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.x + curr.x) / 2;
      final midY = (prev.y + curr.y) / 2;
      path.quadraticBezierTo(prev.x, prev.y, midX, midY);
    }

    path.lineTo(points.last.x, points.last.y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) => true;
}
