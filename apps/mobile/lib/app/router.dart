import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/group_expenses/presentation/screens/add_edit_expense_screen.dart';
import '../features/group_expenses/presentation/screens/create_edit_outing_screen.dart';
import '../features/group_expenses/presentation/screens/expense_details_screen.dart';
import '../features/group_expenses/presentation/screens/member_management_screen.dart';
import '../features/group_expenses/presentation/screens/outing_dashboard_screen.dart';
import '../features/group_expenses/presentation/screens/outing_settings_screen.dart';
import '../features/group_expenses/presentation/screens/outings_list_screen.dart';
import '../features/group_expenses/presentation/screens/record_repayment_screen.dart';
import '../features/group_expenses/presentation/screens/repayment_history_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration for MyDay.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // 1. Today
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              name: 'today',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TodayScreen()),
            ),
          ],
        ),
        // 2. Tasks
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              name: 'tasks',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TasksScreen()),
            ),
          ],
        ),
        // 3. Calendar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              name: 'calendar',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
          ],
        ),
        // 4. Finance
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/finance',
              name: 'finance',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FinanceScreen()),
            ),
          ],
        ),
        // 5. Notes
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              name: 'notes',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: NotesScreen()),
            ),
          ],
        ),
      ],
    ),
    // Profile Route (Pushed on top of root navigator)
    GoRoute(
      path: '/profile',
      name: 'profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    // Settings Route (Pushed on top of root navigator)
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    // MyDay Split: Outings List
    GoRoute(
      path: '/split',
      name: 'split',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OutingsListScreen(),
    ),
    // MyDay Split: Create Outing
    GoRoute(
      path: '/split/create',
      name: 'split_create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateEditOutingScreen(),
    ),
    // MyDay Split: Outing Dashboard
    GoRoute(
      path: '/split/:id',
      name: 'split_dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OutingDashboardScreen(outingId: id);
      },
    ),
    // MyDay Split: Edit Outing
    GoRoute(
      path: '/split/:id/edit',
      name: 'split_edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CreateEditOutingScreen(outingId: id);
      },
    ),
    // MyDay Split: Manage Friends
    GoRoute(
      path: '/split/:id/members',
      name: 'split_members',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MemberManagementScreen(outingId: id);
      },
    ),
    // MyDay Split: Add Expense
    GoRoute(
      path: '/split/:id/expenses/add',
      name: 'split_expense_add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddEditExpenseScreen(outingId: id);
      },
    ),
    // MyDay Split: Expense Details
    GoRoute(
      path: '/split/:id/expenses/:expenseId',
      name: 'split_expense_details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final expenseId = state.pathParameters['expenseId']!;
        return ExpenseDetailsScreen(outingId: id, expenseId: expenseId);
      },
    ),
    // MyDay Split: Edit Expense
    GoRoute(
      path: '/split/:id/expenses/:expenseId/edit',
      name: 'split_expense_edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final expenseId = state.pathParameters['expenseId']!;
        return AddEditExpenseScreen(outingId: id, expenseId: expenseId);
      },
    ),
    // MyDay Split: Record Repayment
    GoRoute(
      path: '/split/:id/settle',
      name: 'split_settle',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final from = state.uri.queryParameters['from'];
        final to = state.uri.queryParameters['to'];
        final amount = int.tryParse(state.uri.queryParameters['amount'] ?? '');
        return RecordRepaymentScreen(
          outingId: id,
          initialFromMemberId: from,
          initialToMemberId: to,
          initialAmountMinor: amount,
        );
      },
    ),
    // MyDay Split: Repayment History
    GoRoute(
      path: '/split/:id/settlements',
      name: 'split_settlements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RepaymentHistoryScreen(outingId: id);
      },
    ),
    // MyDay Split: Outing Settings
    GoRoute(
      path: '/split/:id/settings',
      name: 'split_settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OutingSettingsScreen(outingId: id);
      },
    ),
  ],
);
