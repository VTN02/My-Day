import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../repositories/finance_repository.dart';
import '../repositories/habits_repository.dart';
import '../repositories/notes_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/tasks_repository.dart';

/// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Tasks repository provider
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return DriftTasksRepository(ref.watch(appDatabaseProvider));
});

/// Finance repository provider
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return DriftFinanceRepository(ref.watch(appDatabaseProvider));
});

/// Notes repository provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return DriftNotesRepository(ref.watch(appDatabaseProvider));
});

/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(ref.watch(appDatabaseProvider));
});

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Habits repository provider
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return DriftHabitsRepository(ref.watch(appDatabaseProvider));
});

/// Reactive Habits stream providers
final activeHabitsStreamProvider = StreamProvider<List<HabitEntry>>((ref) {
  return ref.watch(habitsRepositoryProvider).watchActiveHabits();
});

final todayHabitLogsStreamProvider = StreamProvider<List<HabitLogEntry>>((ref) {
  return ref.watch(habitsRepositoryProvider).watchTodayLogs();
});

final habitLogsForDateStreamProvider =
    StreamProvider.family<List<HabitLogEntry>, DateTime>((ref, date) {
      return ref.watch(habitsRepositoryProvider).watchLogsForDate(date);
    });

// Reactive Streams Providers for UI Consumption
final allTasksStreamProvider = StreamProvider<List<TaskEntry>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchAllTasks();
});

final todayTasksStreamProvider = StreamProvider<List<TaskEntry>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchTodayTasks();
});

final tasksForDateStreamProvider =
    StreamProvider.family<List<TaskEntry>, DateTime>((ref, date) {
      return ref.watch(tasksRepositoryProvider).watchTasksForDate(date);
    });


final financialAccountsStreamProvider =
    StreamProvider<List<FinancialAccountEntry>>((ref) {
      return ref.watch(financeRepositoryProvider).watchAccounts();
    });

final recentTransactionsStreamProvider =
    StreamProvider<List<FinancialTransactionEntry>>((ref) {
      return ref
          .watch(financeRepositoryProvider)
          .watchRecentTransactions(limit: 10);
    });

final allTransactionsStreamProvider =
    StreamProvider<List<FinancialTransactionEntry>>((ref) {
      return ref.watch(financeRepositoryProvider).watchAllTransactions();
    });

final currentMonthBudgetStreamProvider =
    StreamProvider<MonthlyBudgetEntry?>((ref) {
      final now = DateTime.now();
      return ref
          .watch(financeRepositoryProvider)
          .watchBudgetForMonth(now.year, now.month);
    });

final allNotesStreamProvider = StreamProvider<List<NoteEntry>>((ref) {
  return ref.watch(notesRepositoryProvider).watchAllNotes();
});

final noteAttachmentsStreamProvider =
    StreamProvider.family<List<NoteAttachmentEntry>, String>((ref, noteId) {
      return ref.watch(notesRepositoryProvider).watchAttachmentsForNote(noteId);
    });


final userProfileStreamProvider = StreamProvider<UserProfileEntry?>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

/// Reactive ThemeMode provider synced to SQLite app_settings
final appThemeModeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('theme_mode')
      .map((val) {
        switch (val) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          default:
            return ThemeMode.system;
        }
      });
});

/// Reactive App Locale provider synced to SQLite app_settings
final appLocaleProvider = StreamProvider<Locale?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('language')
      .map((val) {
        if (val == 'ta') return const Locale('ta');
        if (val == 'si') return const Locale('si');
        if (val == 'en') return const Locale('en');
        return null; // System default
      });
});

/// Reactive Currency provider synced to SQLite app_settings
final appCurrencyProvider = StreamProvider<String>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('currency')
      .map((val) => val ?? 'LKR');
});

