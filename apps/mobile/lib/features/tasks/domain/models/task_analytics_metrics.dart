import '../../../../core/database/app_database.dart';
import 'task_status.dart';

/// Aggregated metrics for a given cohort of tasks.
class TaskAnalyticsMetrics {
  final DateTime startDate;
  final DateTime endDate;
  final int totalTasks;
  final int completedOnTime;
  final int completedLate;
  final int currentlyOverdue;
  final int pending;
  final int missedDeadlines; // completedLate + currentlyOverdue
  final double completionRate; // percentage [0, 100]
  final double onTimeCompletionRate; // percentage [0, 100]
  final Map<String, int> priorityBreakdown; // priority -> total count
  final Map<String, int> priorityCompleted; // priority -> completed count
  final Map<DateTime, int>
  dailyCompletionTrend; // normalized day -> completed count

  const TaskAnalyticsMetrics({
    required this.startDate,
    required this.endDate,
    required this.totalTasks,
    required this.completedOnTime,
    required this.completedLate,
    required this.currentlyOverdue,
    required this.pending,
    required this.missedDeadlines,
    required this.completionRate,
    required this.onTimeCompletionRate,
    required this.priorityBreakdown,
    required this.priorityCompleted,
    required this.dailyCompletionTrend,
  });

  /// Computes metrics from real [TaskEntry] records for a specified date range.
  factory TaskAnalyticsMetrics.fromTasks({
    required List<TaskEntry> allTasks,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? evaluationTime,
  }) {
    final evalTime = evaluationTime ?? DateTime.now();

    // Start of the start day and end of the end day
    final startWindow = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    );
    final endWindow = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    // Eligible cohort:
    // 1. Tasks whose dueDate is within the window.
    // 2. OR tasks with no dueDate that were completed or created within this window.
    final cohort = allTasks.where((task) {
      if (task.dueDate != null) {
        return task.dueDate!.isAfter(
              startWindow.subtract(const Duration(milliseconds: 1)),
            ) &&
            task.dueDate!.isBefore(
              endWindow.add(const Duration(milliseconds: 1)),
            );
      } else {
        final refDate = task.completedAt ?? task.createdAt;
        return refDate.isAfter(
              startWindow.subtract(const Duration(milliseconds: 1)),
            ) &&
            refDate.isBefore(endWindow.add(const Duration(milliseconds: 1)));
      }
    }).toList();

    int onTimeCount = 0;
    int lateCount = 0;
    int overdueCount = 0;
    int pendingCount = 0;

    final Map<String, int> pTotal = {'high': 0, 'medium': 0, 'low': 0};
    final Map<String, int> pCompleted = {'high': 0, 'medium': 0, 'low': 0};
    final Map<DateTime, int> trend = {};

    for (final task in cohort) {
      final status = task.computeStatus(evaluationTime: evalTime);

      switch (status) {
        case TaskStatus.completedOnTime:
          onTimeCount++;
          break;
        case TaskStatus.completedLate:
          lateCount++;
          break;
        case TaskStatus.overdue:
          overdueCount++;
          break;
        case TaskStatus.pending:
        case TaskStatus.inProgress:
        case TaskStatus.cancelled:
          pendingCount++;
          break;
      }

      // Priority tracking
      final pKey = task.priority.toLowerCase();
      pTotal[pKey] = (pTotal[pKey] ?? 0) + 1;
      if (task.isCompleted) {
        pCompleted[pKey] = (pCompleted[pKey] ?? 0) + 1;
      }

      // Daily completion trend
      if (task.isCompleted && task.completedAt != null) {
        final d = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        trend[d] = (trend[d] ?? 0) + 1;
      }
    }

    final total = cohort.length;
    final totalCompleted = onTimeCount + lateCount;
    final missed = lateCount + overdueCount;

    final compRate = total == 0 ? 0.0 : (totalCompleted / total) * 100.0;
    final onTimeRate = totalCompleted == 0
        ? 0.0
        : (onTimeCount / totalCompleted) * 100.0;

    return TaskAnalyticsMetrics(
      startDate: startWindow,
      endDate: endWindow,
      totalTasks: total,
      completedOnTime: onTimeCount,
      completedLate: lateCount,
      currentlyOverdue: overdueCount,
      pending: pendingCount,
      missedDeadlines: missed,
      completionRate: compRate,
      onTimeCompletionRate: onTimeRate,
      priorityBreakdown: pTotal,
      priorityCompleted: pCompleted,
      dailyCompletionTrend: trend,
    );
  }
}
