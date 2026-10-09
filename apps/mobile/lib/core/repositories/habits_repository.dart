import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

abstract class HabitsRepository {
  Stream<List<HabitEntry>> watchActiveHabits();
  Stream<List<HabitLogEntry>> watchLogsForDate(DateTime date);
  Stream<List<HabitLogEntry>> watchTodayLogs();
  Future<void> toggleHabitForDate(String habitId, DateTime date);
  Future<String> createHabit({
    required String title,
    String? description,
    String category = 'Health',
    String frequency = 'daily',
    String color = 'indigo',
  });
  Future<void> archiveHabit(String habitId);
  Future<void> deleteHabit(String habitId);
  Future<int> getStreakForHabit(String habitId);
}

class DriftHabitsRepository implements HabitsRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftHabitsRepository(this._db);

  @override
  Stream<List<HabitEntry>> watchActiveHabits() {
    final query = _db.select(_db.habitsTable)
      ..where((h) => h.isArchived.equals(false))
      ..orderBy([
        (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Stream<List<HabitLogEntry>> watchLogsForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    final query = _db.select(_db.habitLogsTable)
      ..where((l) => l.logDate.equals(normalized));
    return query.watch();
  }

  @override
  Stream<List<HabitLogEntry>> watchTodayLogs() {
    return watchLogsForDate(DateTime.now());
  }

  @override
  Future<void> toggleHabitForDate(String habitId, DateTime date) async {
    final normalized = _normalizeDate(date);
    final existing =
        await (_db.select(_db.habitLogsTable)..where(
              (l) => l.habitId.equals(habitId) & l.logDate.equals(normalized),
            ))
            .getSingleOrNull();

    if (existing != null) {
      if (existing.isCompleted) {
        await (_db.delete(
          _db.habitLogsTable,
        )..where((l) => l.id.equals(existing.id))).go();
      } else {
        await (_db.update(_db.habitLogsTable)
              ..where((l) => l.id.equals(existing.id)))
            .write(const HabitLogsTableCompanion(isCompleted: Value(true)));
      }
    } else {
      await _db
          .into(_db.habitLogsTable)
          .insert(
            HabitLogsTableCompanion.insert(
              id: _uuid.v4(),
              habitId: habitId,
              logDate: normalized,
              isCompleted: const Value(true),
              createdAt: Value(DateTime.now()),
            ),
          );
    }
  }

  @override
  Future<String> createHabit({
    required String title,
    String? description,
    String category = 'Health',
    String frequency = 'daily',
    String color = 'indigo',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.habitsTable)
        .insert(
          HabitsTableCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            category: Value(category),
            frequency: Value(frequency),
            color: Value(color),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await (_db.update(
      _db.habitsTable,
    )..where((h) => h.id.equals(habitId))).write(
      HabitsTableCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.habitLogsTable,
      )..where((l) => l.habitId.equals(habitId))).go();
      await (_db.delete(
        _db.habitsTable,
      )..where((h) => h.id.equals(habitId))).go();
    });
  }

  @override
  Future<int> getStreakForHabit(String habitId) async {
    final logs =
        await (_db.select(_db.habitLogsTable)
              ..where(
                (l) => l.habitId.equals(habitId) & l.isCompleted.equals(true),
              )
              ..orderBy([
                (l) => OrderingTerm(
                  expression: l.logDate,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    if (logs.isEmpty) return 0;

    final today = _normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final logDates = logs.map((l) => _normalizeDate(l.logDate)).toSet();

    // If neither today nor yesterday is completed, streak is broken
    DateTime checkDate;
    if (logDates.contains(today)) {
      checkDate = today;
    } else if (logDates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (logDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
