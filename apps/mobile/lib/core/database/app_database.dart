import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/budgets_table.dart';
import 'tables/financial_accounts_table.dart';
import 'tables/financial_transactions_table.dart';
import 'tables/habits_table.dart';
import 'tables/notes_table.dart';
import 'tables/task_categories_table.dart';
import 'tables/tasks_table.dart';
import 'tables/user_profile_table.dart';

part 'app_database.g.dart';

/// Central Drift Database for MyDay offline persistence.
@DriftDatabase(
  tables: [
    TasksTable,
    TaskCategoriesTable,
    FinancialAccountsTable,
    FinancialTransactionsTable,
    MonthlyBudgetsTable,
    BudgetAllocationsTable,
    NotesTable,
    NoteAttachmentsTable,
    UserProfileTable,
    AppSettingsTable,
    HabitsTable,
    HabitLogsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedInitialData();
    },
  );

  Future<void> _seedInitialData() async {
    final now = DateTime.now();

    // 1. Seed Financial Accounts (Cash and Card)
    await into(financialAccountsTable).insert(
      FinancialAccountsTableCompanion.insert(
        id: 'account_cash',
        name: 'Cash',
        type: 'cash',
        openingBalanceCents: const Value(0),
        currentBalanceCents: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    await into(financialAccountsTable).insert(
      FinancialAccountsTableCompanion.insert(
        id: 'account_card',
        name: 'Card',
        type: 'card',
        openingBalanceCents: const Value(0),
        currentBalanceCents: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // 2. Seed Default User Profile
    await into(userProfileTable).insert(
      UserProfileTableCompanion.insert(
        id: 'me',
        displayName: 'MyDay User',
        bio: const Value('Building better habits, one day at a time.'),
        preferredLanguage: const Value('en'),
        preferredCurrency: const Value('LKR'),
        updatedAt: Value(now),
      ),
    );

    // 3. Seed Default Task Categories
    final defaultCategories = [
      ('cat_work', 'Work', '#4F46E5', 'work'),
      ('cat_personal', 'Personal', '#10B981', 'person'),
      ('cat_study', 'Study', '#7C3AED', 'school'),
      ('cat_health', 'Health', '#06B6D4', 'favorite'),
    ];

    for (final cat in defaultCategories) {
      await into(taskCategoriesTable).insert(
        TaskCategoriesTableCompanion.insert(
          id: cat.$1,
          name: cat.$2,
          colorHex: Value(cat.$3),
          iconName: Value(cat.$4),
          createdAt: Value(now),
        ),
      );
    }

    // 4. Seed Default Habits
    final defaultHabits = [
      ('habit_1', 'Morning Stretch & Mobility', 'Health', 'indigo', '10 mins of gentle stretching and breathing'),
      ('habit_2', 'Drink 2L Water', 'Health', 'teal', 'Track daily hydration intake'),
      ('habit_3', 'Read 15 Pages', 'Personal', 'violet', 'Read a non-fiction or educational book'),
    ];

    for (final h in defaultHabits) {
      await into(habitsTable).insert(
        HabitsTableCompanion.insert(
          id: h.$1,
          title: h.$2,
          category: Value(h.$3),
          color: Value(h.$4),
          description: Value(h.$5),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
