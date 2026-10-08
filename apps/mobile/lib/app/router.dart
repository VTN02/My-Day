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
  ],
);
