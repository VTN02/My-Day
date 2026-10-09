import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

abstract class TasksRepository {
  Stream<List<TaskEntry>> watchAllTasks();
  Stream<List<TaskEntry>> watchTasksForDate(DateTime date);
  Stream<List<TaskEntry>> watchTodayTasks();
  Future<TaskEntry?> getTask(String id);
  Future<String> createTask({
    required String title,
    String? description,
    String category = 'General',
    String priority = 'medium',
    DateTime? dueDate,
    String? dueTime,
    String reminder = 'none',
  });
  Future<void> updateTask(TaskEntry task);
  Future<void> toggleTaskCompletion(String id);
  Future<void> deleteTask(String id);
}

class DriftTasksRepository implements TasksRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftTasksRepository(this._db);

  @override
  Stream<List<TaskEntry>> watchAllTasks() {
    final query = _db.select(_db.tasksTable)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Stream<List<TaskEntry>> watchTasksForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final query = _db.select(_db.tasksTable)
      ..where(
        (t) =>
            t.dueDate.isBiggerOrEqualValue(startOfDay) &
            t.dueDate.isSmallerOrEqualValue(endOfDay),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  @override
  Stream<List<TaskEntry>> watchTodayTasks() {
    return watchTasksForDate(DateTime.now());
  }

  @override
  Future<TaskEntry?> getTask(String id) {
    return (_db.select(
      _db.tasksTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<String> createTask({
    required String title,
    String? description,
    String category = 'General',
    String priority = 'medium',
    DateTime? dueDate,
    String? dueTime,
    String reminder = 'none',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db
        .into(_db.tasksTable)
        .insert(
          TasksTableCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            category: Value(category),
            priority: Value(priority),
            dueDate: Value(dueDate),
            dueTime: Value(dueTime),
            reminder: Value(reminder),
            isCompleted: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  @override
  Future<void> updateTask(TaskEntry task) async {
    await (_db.update(
      _db.tasksTable,
    )..where((t) => t.id.equals(task.id))).write(
      TasksTableCompanion(
        title: Value(task.title),
        description: Value(task.description),
        category: Value(task.category),
        priority: Value(task.priority),
        dueDate: Value(task.dueDate),
        dueTime: Value(task.dueTime),
        reminder: Value(task.reminder),
        isCompleted: Value(task.isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    final task = await getTask(id);
    if (task == null) return;

    await (_db.update(_db.tasksTable)..where((t) => t.id.equals(id))).write(
      TasksTableCompanion(
        isCompleted: Value(!task.isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.tasksTable)..where((t) => t.id.equals(id))).go();
  }
}
