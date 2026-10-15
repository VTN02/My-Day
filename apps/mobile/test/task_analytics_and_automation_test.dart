import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/repositories/notes_repository.dart';
import 'package:mobile/core/repositories/tasks_repository.dart';
import 'package:mobile/features/notes/domain/models/note.dart';
import 'package:mobile/features/notes/domain/models/note_block.dart';
import 'package:mobile/features/notes/domain/models/note_template.dart';
import 'package:mobile/features/tasks/domain/models/task_analytics_metrics.dart';
import 'package:mobile/features/tasks/domain/models/task_status.dart';

void main() {
  group('Task Status & Deadline Derivation Unit Tests', () {
    test(
      'Task with no due date evaluates to pending when incomplete and completedOnTime when completed',
      () {
        final incompleteTask = TaskEntry(
          id: 't1',
          title: 'Undated Task',
          category: 'General',
          priority: 'medium',
          isCompleted: false,
          followUpEnabled: false,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        );

        expect(incompleteTask.computedDeadline, isNull);
        expect(incompleteTask.computeStatus(), equals(TaskStatus.pending));

        final completedTask = incompleteTask.copyWith(
          isCompleted: true,
          completedAt: drift.Value(DateTime(2026, 10, 5)),
        );
        expect(
          completedTask.computeStatus(),
          equals(TaskStatus.completedOnTime),
        );
      },
    );

    test(
      'Date-only task deadline is end of local calendar day (23:59:59.999)',
      () {
        final dueDate = DateTime(2026, 10, 15);
        final task = TaskEntry(
          id: 't2',
          title: 'Date Only Task',
          category: 'Work',
          priority: 'high',
          dueDate: dueDate,
          isCompleted: false,
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        );

        final deadline = task.computedDeadline;
        expect(deadline, isNotNull);
        expect(deadline!.year, equals(2026));
        expect(deadline.month, equals(10));
        expect(deadline.day, equals(15));
        expect(deadline.hour, equals(23));
        expect(deadline.minute, equals(59));

        // Before end of day
        final beforeEndOfDay = DateTime(2026, 10, 15, 14, 0);
        expect(
          task.computeStatus(evaluationTime: beforeEndOfDay),
          equals(TaskStatus.pending),
        );

        // Next day -> overdue
        final nextDay = DateTime(2026, 10, 16, 8, 0);
        expect(
          task.computeStatus(evaluationTime: nextDay),
          equals(TaskStatus.overdue),
        );
      },
    );

    test(
      'Date and time task evaluates accurately for on-time and late completion',
      () {
        final dueDate = DateTime(2026, 10, 15);
        final dueTime = '10:00 AM';

        final task = TaskEntry(
          id: 't3',
          title: 'Meeting Task',
          category: 'Work',
          priority: 'high',
          dueDate: dueDate,
          dueTime: dueTime,
          isCompleted: false,
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        );

        final deadline = task.computedDeadline;
        expect(deadline, equals(DateTime(2026, 10, 15, 10, 0)));

        // Incomplete before 10 AM -> Pending
        expect(
          task.computeStatus(evaluationTime: DateTime(2026, 10, 15, 9, 30)),
          equals(TaskStatus.pending),
        );

        // Incomplete after 10 AM -> Overdue
        expect(
          task.computeStatus(evaluationTime: DateTime(2026, 10, 15, 10, 15)),
          equals(TaskStatus.overdue),
        );

        // Completed at 9:55 AM -> Completed On Time
        final onTimeTask = task.copyWith(
          isCompleted: true,
          completedAt: drift.Value(DateTime(2026, 10, 15, 9, 55)),
        );
        expect(onTimeTask.computeStatus(), equals(TaskStatus.completedOnTime));

        // Completed at 10:30 AM -> Completed Late
        final lateTask = task.copyWith(
          isCompleted: true,
          completedAt: drift.Value(DateTime(2026, 10, 15, 10, 30)),
        );
        expect(lateTask.computeStatus(), equals(TaskStatus.completedLate));
      },
    );
  });

  group('Task Analytics Cohort Metrics & Zero-Division Safety', () {
    test(
      'Zero eligible tasks produces 0.0% completion and on-time rates without division by zero',
      () {
        final metrics = TaskAnalyticsMetrics.fromTasks(
          allTasks: [],
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 7),
        );

        expect(metrics.totalTasks, equals(0));
        expect(metrics.completedOnTime, equals(0));
        expect(metrics.completedLate, equals(0));
        expect(metrics.currentlyOverdue, equals(0));
        expect(metrics.pending, equals(0));
        expect(metrics.missedDeadlines, equals(0));
        expect(metrics.completionRate, equals(0.0));
        expect(metrics.onTimeCompletionRate, equals(0.0));
      },
    );

    test(
      'Computes accurate rates and missed deadlines across mixed task cohorts',
      () {
        final evalTime = DateTime(2026, 10, 15, 12, 0);

        final taskOnTime = TaskEntry(
          id: '1',
          title: 'Task 1',
          category: 'Study',
          priority: 'high',
          dueDate: DateTime(2026, 10, 12, 10, 0),
          dueTime: '10:00 AM',
          isCompleted: true,
          completedAt: DateTime(2026, 10, 12, 9, 0),
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 12),
        );

        final taskLate = TaskEntry(
          id: '2',
          title: 'Task 2',
          category: 'Work',
          priority: 'medium',
          dueDate: DateTime(2026, 10, 13, 15, 0),
          dueTime: '03:00 PM',
          isCompleted: true,
          completedAt: DateTime(2026, 10, 13, 18, 0),
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 13),
        );

        final taskOverdue = TaskEntry(
          id: '3',
          title: 'Task 3',
          category: 'Personal',
          priority: 'low',
          dueDate: DateTime(2026, 10, 14, 12, 0),
          dueTime: '12:00 PM',
          isCompleted: false,
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        );

        final taskPending = TaskEntry(
          id: '4',
          title: 'Task 4',
          category: 'Health',
          priority: 'medium',
          dueDate: DateTime(2026, 10, 15, 18, 0),
          dueTime: '06:00 PM',
          isCompleted: false,
          followUpEnabled: true,
          followUpDelayMinutes: 10,
          maxRepeats: 2,
          reminder: 'none',
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        );

        final metrics = TaskAnalyticsMetrics.fromTasks(
          allTasks: [taskOnTime, taskLate, taskOverdue, taskPending],
          startDate: DateTime(2026, 10, 11),
          endDate: DateTime(2026, 10, 17),
          evaluationTime: evalTime,
        );

        expect(metrics.totalTasks, equals(4));
        expect(metrics.completedOnTime, equals(1));
        expect(metrics.completedLate, equals(1));
        expect(metrics.currentlyOverdue, equals(1));
        expect(metrics.pending, equals(1));
        expect(metrics.missedDeadlines, equals(2)); // late(1) + overdue(1)
        expect(metrics.completionRate, equals(50.0)); // 2 completed of 4
        expect(
          metrics.onTimeCompletionRate,
          equals(50.0),
        ); // 1 on-time of 2 completed
        expect(metrics.priorityBreakdown['high'], equals(1));
        expect(metrics.priorityBreakdown['medium'], equals(2));
        expect(metrics.priorityBreakdown['low'], equals(1));
        expect(metrics.priorityCompleted['high'], equals(1));
      },
    );
  });

  group('Drift Task Repository & Schema Integration', () {
    late AppDatabase db;
    late DriftTasksRepository tasksRepo;
    late DriftNotesRepository notesRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tasksRepo = DriftTasksRepository(db);
      notesRepo = DriftNotesRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'createTask persists followUpEnabled, delay, repeats and null completedAt',
      () async {
        final taskId = await tasksRepo.createTask(
          title: 'Study Flutter',
          category: 'Study',
          priority: 'high',
          dueDate: DateTime(2026, 10, 20),
          dueTime: '08:00 AM',
          followUpEnabled: true,
          followUpDelayMinutes: 15,
          maxRepeats: 3,
          selectedTuneId: 'bell',
        );

        final task = await tasksRepo.getTask(taskId);
        expect(task, isNotNull);
        expect(task!.title, equals('Study Flutter'));
        expect(task.isCompleted, isFalse);
        expect(task.completedAt, isNull);
        expect(task.followUpEnabled, isTrue);
        expect(task.followUpDelayMinutes, equals(15));
        expect(task.maxRepeats, equals(3));
        expect(task.selectedTuneId, equals('bell'));
      },
    );

    test(
      'toggleTaskCompletion records completedAt on completion and clears it on reopen',
      () async {
        final taskId = await tasksRepo.createTask(
          title: 'Buy Groceries',
          category: 'Personal',
          dueDate: DateTime.now(),
        );

        // Toggle to Completed
        await tasksRepo.toggleTaskCompletion(taskId);
        var task = await tasksRepo.getTask(taskId);
        expect(task!.isCompleted, isTrue);
        expect(task.completedAt, isNotNull);

        // Toggle back to Incomplete (Reopened)
        await tasksRepo.toggleTaskCompletion(taskId);
        task = await tasksRepo.getTask(taskId);
        expect(task!.isCompleted, isFalse);
        expect(task.completedAt, isNull);
      },
    );

    test(
      'Save Task Analytics Report to Notes saves structured Note and retrieves faithfully',
      () async {
        final now = DateTime.now();
        final blocks = [
          NoteBlock(
            id: 'b1',
            type: NoteBlockType.heading1,
            text: 'Weekly Task Summary — Oct 12–18',
          ),
          NoteBlock(
            id: 'b2',
            type: NoteBlockType.richText,
            text: 'Generated on 2026-10-15 • Completion Rate: 85.0%',
          ),
          NoteBlock(
            id: 'b3',
            type: NoteBlockType.bullet,
            text: 'Completed On Time: 10',
          ),
          NoteBlock(
            id: 'b4',
            type: NoteBlockType.bullet,
            text: 'Completed Late: 2',
          ),
        ];

        final note = Note(
          id: 'report_note_1',
          title: 'Weekly Task Summary — Oct 12–18',
          body: 'Weekly report snapshot',
          category: 'Analytics',
          templateType: NoteTemplateType.blank,
          blocks: blocks,
          createdAt: now,
          updatedAt: now,
        );

        await notesRepo.saveNote(note);

        final retrieved = await notesRepo.getNoteById('report_note_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Weekly Task Summary — Oct 12–18'));
        expect(retrieved.blocks.length, equals(4));
        expect(retrieved.blocks[0].type, equals(NoteBlockType.heading1));
        expect(retrieved.blocks[2].text, equals('Completed On Time: 10'));
      },
    );
  });
}
