import 'dart:convert';
import 'package:flutter/material.dart';

/// Single point within a vector stroke.
class StrokePoint {
  final double x;
  final double y;
  final double pressure;

  const StrokePoint({required this.x, required this.y, this.pressure = 1.0});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['p'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

enum StrokeTool {
  pen,
  pencil,
  highlighter,
  brush,
  eraser,
  line,
  rectangle,
  circle,
  arrow;

  static StrokeTool fromString(String val) {
    switch (val.toLowerCase()) {
      case 'pencil':
        return StrokeTool.pencil;
      case 'highlighter':
        return StrokeTool.highlighter;
      case 'brush':
        return StrokeTool.brush;
      case 'eraser':
        return StrokeTool.eraser;
      case 'line':
        return StrokeTool.line;
      case 'rectangle':
      case 'rect':
        return StrokeTool.rectangle;
      case 'circle':
      case 'oval':
        return StrokeTool.circle;
      case 'arrow':
        return StrokeTool.arrow;
      case 'pen':
      default:
        return StrokeTool.pen;
    }
  }

  bool get isShape =>
      this == StrokeTool.line ||
      this == StrokeTool.rectangle ||
      this == StrokeTool.circle ||
      this == StrokeTool.arrow;
}

/// An editable vector stroke consisting of points, tool type, color, and width.
class DrawingStroke {
  final String id;
  final List<StrokePoint> points;
  final StrokeTool tool;
  final String colorHex;
  final double strokeWidth;

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.tool,
    required this.colorHex,
    required this.strokeWidth,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    final intColor = int.tryParse(hex, radix: 16) ?? 0xFF000000;
    Color base;
    if (hex.length == 6) {
      base = Color(0xFF000000 | intColor);
    } else {
      base = Color(intColor);
    }

    if (tool == StrokeTool.highlighter) {
      return base.withValues(alpha: 0.35);
    } else if (tool == StrokeTool.pencil) {
      return base.withValues(alpha: 0.70);
    }
    return base;
  }

  DrawingStroke copyWith({
    String? id,
    List<StrokePoint>? points,
    StrokeTool? tool,
    String? colorHex,
    double? strokeWidth,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      tool: tool ?? this.tool,
      colorHex: colorHex ?? this.colorHex,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'tool': tool.name,
    'color': colorHex,
    'width': strokeWidth,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      id: json['id'] as String,
      points:
          (json['points'] as List<dynamic>?)
              ?.map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      tool: StrokeTool.fromString(json['tool'] as String? ?? 'pen'),
      colorHex: json['color'] as String? ?? '#1565C0',
      strokeWidth: (json['width'] as num?)?.toDouble() ?? 3.0,
    );
  }

  static String encodeList(List<DrawingStroke> strokes) {
    return jsonEncode(strokes.map((s) => s.toJson()).toList());
  }

  static List<DrawingStroke> decodeList(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => DrawingStroke.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
