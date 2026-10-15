import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/summary_card.dart';
import '../../notes/domain/models/note.dart';
import '../../notes/domain/models/note_block.dart';
import '../../notes/domain/models/note_template.dart';
import '../domain/models/task_analytics_metrics.dart';
import 'task_analytics_charts.dart';

enum TaskAnalyticsPeriod { today, thisWeek, thisMonth, custom }

class TaskAnalyticsScreen extends ConsumerStatefulWidget {
  const TaskAnalyticsScreen({super.key});

  @override
  ConsumerState<TaskAnalyticsScreen> createState() =>
      _TaskAnalyticsScreenState();
}

class _TaskAnalyticsScreenState extends ConsumerState<TaskAnalyticsScreen> {
  TaskAnalyticsPeriod _selectedPeriod = TaskAnalyticsPeriod.thisWeek;
  DateTimeRange? _customDateRange;

  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case TaskAnalyticsPeriod.today:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day),
        );
      case TaskAnalyticsPeriod.thisWeek:
        // Week starting Monday (ISO-8601)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (
          DateTime(monday.year, monday.month, monday.day),
          DateTime(sunday.year, sunday.month, sunday.day),
        );
      case TaskAnalyticsPeriod.thisMonth:
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        return (firstDay, lastDay);
      case TaskAnalyticsPeriod.custom:
        if (_customDateRange != null) {
          return (_customDateRange!.start, _customDateRange!.end);
        }
        return (now.subtract(const Duration(days: 7)), now);
    }
  }

  String _formatPeriodLabel(DateTime start, DateTime end) {
    final format = DateFormat('MMM d, y');
    if (DateUtils.isSameDay(start, end)) {
      return format.format(start);
    }
    return '${DateFormat('MMM d').format(start)} – ${format.format(end)}';
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 730)),
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = TaskAnalyticsPeriod.custom;
      });
    }
  }

  Future<void> _exportReportToNotes(TaskAnalyticsMetrics metrics) async {
    final now = DateTime.now();
    final periodName = switch (_selectedPeriod) {
      TaskAnalyticsPeriod.today => 'Today',
      TaskAnalyticsPeriod.thisWeek => 'Weekly',
      TaskAnalyticsPeriod.thisMonth => 'Monthly',
      TaskAnalyticsPeriod.custom => 'Custom Range',
    };
    final dateRangeStr = _formatPeriodLabel(metrics.startDate, metrics.endDate);
    final reportTitle = '$periodName Task Summary — $dateRangeStr';

    final blocks = <NoteBlock>[
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.heading1,
        text: '📋 Task Analytics Report',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.richText,
        text:
            'Period: $dateRangeStr • Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.heading2,
        text: 'Performance Metrics',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Total Eligible Tasks: ${metrics.totalTasks}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Completed On Time: ${metrics.completedOnTime}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Completed Late: ${metrics.completedLate}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Currently Overdue: ${metrics.currentlyOverdue}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Pending Tasks: ${metrics.pending}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text: 'Missed Deadlines (Late + Overdue): ${metrics.missedDeadlines}',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text:
            'Overall Completion Rate: ${metrics.completionRate.toStringAsFixed(1)}%',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.bullet,
        text:
            'On-Time Completion Rate: ${metrics.onTimeCompletionRate.toStringAsFixed(1)}%',
      ),
      NoteBlock(
        id: const Uuid().v4(),
        type: NoteBlockType.heading2,
        text: 'Priority Distribution',
      ),
      ...metrics.priorityBreakdown.entries.map((entry) {
        final comp = metrics.priorityCompleted[entry.key] ?? 0;
        return NoteBlock(
          id: const Uuid().v4(),
          type: NoteBlockType.bullet,
          text: '${entry.key.toUpperCase()}: $comp of ${entry.value} completed',
        );
      }),
    ];

    final note = Note(
      id: const Uuid().v4(),
      title: reportTitle,
      body:
          'Task Analytics snapshot for $dateRangeStr. Completion rate: ${metrics.completionRate.toStringAsFixed(1)}%.',
      category: 'Analytics',
      templateType: NoteTemplateType.blank,
      blocks: blocks,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(notesRepositoryProvider).saveNote(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to Notes: "$reportTitle"'),
          backgroundColor: AppColors.successMint,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              context.push('/notes/${note.id}');
            },
          ),
        ),
      );
    }
  }

  Widget _buildFilterChip(
    TaskAnalyticsPeriod period,
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        if (period == TaskAnalyticsPeriod.custom) {
          _pickCustomDateRange();
        } else {
          setState(() => _selectedPeriod = period);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryIndigo
              : (isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightBackground),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryIndigo
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTasksAsync = ref.watch(allTasksStreamProvider);

    final (start, end) = _resolveDateRange();
    final periodLabel = _formatPeriodLabel(start, end);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverGradientHeader(
            eyebrow: 'Performance & Insights',
            title: 'Task Analytics',
            subtitle: periodLabel,
            trailing: IconButton(
              tooltip: 'Back to Tasks',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          TaskAnalyticsPeriod.today,
                          'Today',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          TaskAnalyticsPeriod.thisWeek,
                          'This Week',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          TaskAnalyticsPeriod.thisMonth,
                          'This Month',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          TaskAnalyticsPeriod.custom,
                          _selectedPeriod == TaskAnalyticsPeriod.custom &&
                                  _customDateRange != null
                              ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}'
                              : 'Custom Range',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          allTasksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: LoadingState(message: 'Calculating task metrics...'),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading analytics: $err',
                  style: const TextStyle(color: AppColors.errorCoral),
                ),
              ),
            ),
            data: (allTasks) {
              final metrics = TaskAnalyticsMetrics.fromTasks(
                allTasks: allTasks,
                startDate: start,
                endDate: end,
              );

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Key Performance Indicator (KPI) Grid
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Completion Rate',
                            value:
                                '${metrics.completionRate.toStringAsFixed(0)}%',
                            subtitle:
                                '${metrics.completedOnTime + metrics.completedLate} of ${metrics.totalTasks} tasks',
                            icon: Icons.donut_large_rounded,
                            iconColor: AppColors.primaryIndigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            title: 'On-Time Rate',
                            value:
                                '${metrics.onTimeCompletionRate.toStringAsFixed(0)}%',
                            subtitle:
                                '${metrics.completedOnTime} completed on time',
                            icon: Icons.verified_rounded,
                            iconColor: AppColors.successMint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Currently Overdue',
                            value: '${metrics.currentlyOverdue}',
                            subtitle: 'Needs immediate action',
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.errorCoral,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            title: 'Completed Late',
                            value: '${metrics.completedLate}',
                            subtitle:
                                '${metrics.missedDeadlines} missed deadlines',
                            icon: Icons.alarm_off_rounded,
                            iconColor: AppColors.warningAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Chart A: Status Distribution
                    TaskStatusDonutChart(metrics: metrics, isDark: isDark),
                    const SizedBox(height: 16),

                    // Chart B: Daily Trend
                    TaskDailyTrendChart(metrics: metrics, isDark: isDark),
                    const SizedBox(height: 16),

                    // Chart E: Priority Performance
                    TaskPriorityPerformanceChart(
                      metrics: metrics,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Export to Notes Action Button
                    PrimaryButton(
                      text: 'Save Report to Notes',
                      icon: Icons.note_add_rounded,
                      isFullWidth: true,
                      onPressed: () => _exportReportToNotes(metrics),
                    ),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
