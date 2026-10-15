import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

/// Explicit status enumeration for MyDay Tasks.
enum TaskStatus {
  pending,
  inProgress,
  completedOnTime,
  overdue,
  completedLate,
  cancelled;

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completedOnTime:
        return 'Completed On Time';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.completedLate:
        return 'Completed Late';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return AppColors.primaryIndigo;
      case TaskStatus.inProgress:
        return AppColors.accentCyan;
      case TaskStatus.completedOnTime:
        return AppColors.successMint;
      case TaskStatus.overdue:
        return AppColors.errorCoral;
      case TaskStatus.completedLate:
        return AppColors.warningAmber;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.pending:
        return Icons.hourglass_empty_rounded;
      case TaskStatus.inProgress:
        return Icons.timelapse_rounded;
      case TaskStatus.completedOnTime:
        return Icons.check_circle_rounded;
      case TaskStatus.overdue:
        return Icons.warning_amber_rounded;
      case TaskStatus.completedLate:
        return Icons.alarm_off_rounded;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

/// Extension providing deadline calculation and status derivation on [TaskEntry].
extension TaskEntryStatusExtension on TaskEntry {
  /// Computes the exact local deadline based on due date and optional due time.
  /// - No due date: returns null (no deadline).
  /// - Due date with time: returns the exact datetime.
  /// - Due date only: returns the end of that local calendar day (23:59:59.999).
  DateTime? get computedDeadline {
    if (dueDate == null) return null;

    if (dueTime != null && dueTime!.trim().isNotEmpty) {
      final parsed = _parseTime(dueTime!);
      if (parsed != null) {
        return DateTime(
          dueDate!.year,
          dueDate!.month,
          dueDate!.day,
          parsed.$1,
          parsed.$2,
        );
      }
    }

    // Date-only task deadline is the end of the specified calendar day
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Evaluates task status at a given point in time (defaulting to [DateTime.now]).
  TaskStatus computeStatus({DateTime? evaluationTime}) {
    final now = evaluationTime ?? DateTime.now();
    final deadline = computedDeadline;

    if (isCompleted) {
      if (deadline == null) return TaskStatus.completedOnTime;
      // If completedAt is stored and is strictly after the computed deadline, mark Completed Late.
      if (completedAt != null && completedAt!.isAfter(deadline)) {
        return TaskStatus.completedLate;
      }
      return TaskStatus.completedOnTime;
    }

    // Incomplete task
    if (deadline != null && now.isAfter(deadline)) {
      return TaskStatus.overdue;
    }

    return TaskStatus.pending;
  }

  /// Parses strings like "8:00 AM", "14:30", "08:15 PM" into (hour, minute).
  static (int, int)? _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (parts.length >= 3) {
          final isPm = parts[2].toUpperCase() == 'PM';
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
        }
        return (hour, minute);
      }
    } catch (_) {}
    return null;
  }
}
