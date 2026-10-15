import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../domain/models/task_analytics_metrics.dart';
import '../domain/models/task_status.dart';

/// Donut chart displaying the distribution of task statuses.
class TaskStatusDonutChart extends StatelessWidget {
  final TaskAnalyticsMetrics metrics;
  final bool isDark;

  const TaskStatusDonutChart({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.totalTasks == 0) {
      return _buildEmptyState('No tasks in this period to display.');
    }

    final segments = [
      (
        TaskStatus.completedOnTime.label,
        metrics.completedOnTime,
        TaskStatus.completedOnTime.color,
      ),
      (
        TaskStatus.completedLate.label,
        metrics.completedLate,
        TaskStatus.completedLate.color,
      ),
      (
        TaskStatus.overdue.label,
        metrics.currentlyOverdue,
        TaskStatus.overdue.color,
      ),
      (TaskStatus.pending.label, metrics.pending, TaskStatus.pending.color),
    ].where((s) => s.$2 > 0).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: AppColors.primaryIndigo,
              ),
              const SizedBox(width: 8),
              Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _StatusDonutPainter(
                      segments: segments,
                      total: metrics.totalTasks,
                      isDark: isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${metrics.totalTasks}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      Text(
                        'Total Tasks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                TaskStatus.completedOnTime.label,
                metrics.completedOnTime,
                TaskStatus.completedOnTime.color,
              ),
              _buildLegendItem(
                TaskStatus.completedLate.label,
                metrics.completedLate,
                TaskStatus.completedLate.color,
              ),
              _buildLegendItem(
                TaskStatus.overdue.label,
                metrics.currentlyOverdue,
                TaskStatus.overdue.color,
              ),
              _buildLegendItem(
                TaskStatus.pending.label,
                metrics.pending,
                TaskStatus.pending.color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ),
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  final List<(String, int, Color)> segments;
  final int total;
  final bool isDark;

  _StatusDonutPainter({
    required this.segments,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (total == 0) return;

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = (seg.$2 / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Small inset to avoid overlapping rounded caps
      final adjustedSweep = sweepAngle > 0.05 ? sweepAngle - 0.03 : sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        adjustedSweep,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) => true;
}

/// Chart showing task completion counts by priority.
class TaskPriorityPerformanceChart extends StatelessWidget {
  final TaskAnalyticsMetrics metrics;
  final bool isDark;

  const TaskPriorityPerformanceChart({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorities = [
      ('High', 'high', AppColors.priorityHigh),
      ('Medium', 'medium', AppColors.priorityMedium),
      ('Low', 'low', AppColors.priorityLow),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppColors.secondaryViolet,
              ),
              const SizedBox(width: 8),
              Text(
                'Completion by Priority',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...priorities.map((p) {
            final total = metrics.priorityBreakdown[p.$2] ?? 0;
            final completed = metrics.priorityCompleted[p.$2] ?? 0;
            final rate = total == 0 ? 0.0 : (completed / total);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: p.$3,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$completed / $total completed (${(rate * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.darkSoftIndigo
                          : AppColors.lightSoftIndigo,
                      valueColor: AlwaysStoppedAnimation<Color>(p.$3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Bar chart showing daily completion trend.
class TaskDailyTrendChart extends StatelessWidget {
  final TaskAnalyticsMetrics metrics;
  final bool isDark;

  const TaskDailyTrendChart({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.dailyCompletionTrend.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardSurface
              : AppColors.lightCardSurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            'No completed tasks with recorded timestamps in this range.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
        ),
      );
    }

    final sortedDays = metrics.dailyCompletionTrend.keys.toList()..sort();
    final maxCount = metrics.dailyCompletionTrend.values.fold<int>(0, math.max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                size: 18,
                color: AppColors.successMint,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Completion Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedDays.map((day) {
                final count = metrics.dailyCompletionTrend[day] ?? 0;
                final heightFactor = maxCount == 0 ? 0.0 : (count / maxCount);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: math.max(6.0, 80 * heightFactor),
                          decoration: BoxDecoration(
                            color: AppColors.successMint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${day.day}/${day.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
