import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/repositories/habits_repository.dart';

void main() {
  late AppDatabase db;
  late DriftHabitsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftHabitsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftHabitsRepository Unit Tests', () {
    test('creates and retrieves active habit', () async {
      final habitId = await repo.createHabit(
        title: 'Morning Run',
        description: 'Run 5km every morning',
        category: 'Fitness',
        color: 'teal',
      );

      final habits = await repo.watchActiveHabits().first;
      expect(habits.any((h) => h.id == habitId && h.title == 'Morning Run'), isTrue);
    });

    test('toggles habit completion for today and calculates streak', () async {
      final habitId = await repo.createHabit(
        title: 'Hydration 2L',
        category: 'Health',
      );

      // Initially streak is 0
      final initialStreak = await repo.getStreakForHabit(habitId);
      expect(initialStreak, equals(0));

      // Toggle today
      final today = DateTime.now();
      await repo.toggleHabitForDate(habitId, today);

      final streakAfterToday = await repo.getStreakForHabit(habitId);
      expect(streakAfterToday, equals(1));

      // Add yesterday to make a 2-day streak
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.toggleHabitForDate(habitId, yesterday);

      final streakAfterYesterday = await repo.getStreakForHabit(habitId);
      expect(streakAfterYesterday, equals(2));

      // Toggle today off -> removes completion
      await repo.toggleHabitForDate(habitId, today);
      final logs = await repo.watchTodayLogs().first;
      expect(logs.any((l) => l.habitId == habitId), isFalse);
    });

    test('archives habit and hides from active habits list', () async {
      final habitId = await repo.createHabit(
        title: 'Read Book',
        category: 'Learning',
      );

      await repo.archiveHabit(habitId);
      final habits = await repo.watchActiveHabits().first;
      expect(habits.any((h) => h.id == habitId), isFalse);
    });

    test('deletes habit and associated logs', () async {
      final habitId = await repo.createHabit(
        title: 'Meditation',
        category: 'Mind',
      );

      await repo.toggleHabitForDate(habitId, DateTime.now());
      await repo.deleteHabit(habitId);

      final habits = await repo.watchActiveHabits().first;
      expect(habits.any((h) => h.id == habitId), isFalse);

      final logs = await repo.watchTodayLogs().first;
      expect(logs.any((l) => l.habitId == habitId), isFalse);
    });
  });
}
