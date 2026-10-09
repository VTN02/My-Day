import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/widgets/balance_card.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/summary_card.dart';
import 'package:mobile/core/widgets/task_card.dart';

void main() {
  group('Design System Components Test', () {
    testWidgets('SummaryCard renders title, value and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Tasks Done',
              value: '3 / 4',
              subtitle: '1 pending',
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('Tasks Done'), findsOneWidget);
      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.text('1 pending'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('BalanceCard renders account name and formatted balance', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              title: 'Cash Wallet',
              amount: 'Rs. 8,500',
              subtitle: 'Liquid cash',
              icon: Icons.payments_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('Rs. 8,500'), findsOneWidget);
      expect(find.text('Liquid cash'), findsOneWidget);
    });

    testWidgets('TaskCard triggers onToggle checkbox callback', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              title: 'Buy groceries',
              category: 'Personal',
              priority: 'high',
              isCompleted: false,
              onToggle: (val) {
                toggled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('StatusChip handles tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(
              label: 'Work',
              isSelected: false,
              count: 3,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Work'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('MyDayApp App Shell Smoke Test', () {
    testWidgets('Renders MyDayApp and bottom navigation items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appThemeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.system)),
            appLocaleProvider.overrideWith((ref) => Stream.value(const Locale('en'))),
            userProfileStreamProvider.overrideWith((ref) => Stream.value(null)),
            todayTasksStreamProvider.overrideWith((ref) => Stream.value([])),
            financialAccountsStreamProvider.overrideWith((ref) => Stream.value([])),
            activeHabitsStreamProvider.overrideWith((ref) => Stream.value([])),
            todayHabitLogsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MyDayApp(),
        ),
      );
      await tester.pump();

      // Check bottom nav items
      expect(find.text('Today'), findsAtLeastNWidgets(1));
      expect(find.text('Tasks'), findsAtLeastNWidgets(1));
    });
  });
}
