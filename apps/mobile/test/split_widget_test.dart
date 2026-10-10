import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/group_expenses/domain/models/member_balance.dart';
import 'package:mobile/features/group_expenses/domain/models/suggested_settlement.dart';
import 'package:mobile/features/group_expenses/presentation/widgets/budget_progress_bar.dart';
import 'package:mobile/features/group_expenses/presentation/widgets/member_avatar_tile.dart';
import 'package:mobile/features/group_expenses/presentation/widgets/settlement_tile.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('MyDay Split UI Components Tests', () {
    testWidgets('BudgetProgressBar renders spent, remaining, and percentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BudgetProgressBar(
            spentMinor: 1200000, // Rs. 12,000
            budgetMinor: 2000000, // Rs. 20,000
          ),
        ),
      );

      expect(find.text('Budget Usage'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Spent: Rs. 12000'), findsOneWidget);
      expect(find.text('Remaining: Rs. 8000'), findsOneWidget);
    });

    testWidgets('MemberAvatarTile renders creditor status correctly', (
      tester,
    ) async {
      const balance = MemberBalance(
        memberId: 'm_you',
        displayName: 'You',
        isOrganizer: true,
        totalPaidMinor: 600000,
        totalShareMinor: 300000,
      );

      await tester.pumpWidget(
        buildTestableWidget(const MemberAvatarTile(balance: balance)),
      );

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Organizer'), findsOneWidget);
      expect(find.text('Gets +Rs. 3000'), findsOneWidget);
      expect(find.text('Paid: Rs. 6000 • Share: Rs. 3000'), findsOneWidget);
    });

    testWidgets('MemberAvatarTile renders debtor status correctly', (
      tester,
    ) async {
      const balance = MemberBalance(
        memberId: 'm_kavin',
        displayName: 'Kavin',
        isOrganizer: false,
        totalPaidMinor: 0,
        totalShareMinor: 300000,
      );

      await tester.pumpWidget(
        buildTestableWidget(const MemberAvatarTile(balance: balance)),
      );

      expect(find.text('Kavin'), findsOneWidget);
      expect(find.text('Owes -Rs. 3000'), findsOneWidget);
      expect(find.text('Paid: Rs. 0 • Share: Rs. 3000'), findsOneWidget);
    });

    testWidgets('SettlementTile renders debtor to creditor transfer', (
      tester,
    ) async {
      var tapped = false;
      const settlement = SuggestedSettlement(
        fromMemberId: 'm_kavin',
        fromDisplayName: 'Kavin',
        toMemberId: 'm_you',
        toDisplayName: 'You',
        amountMinor: 300000,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          SettlementTile(
            settlement: settlement,
            onSettleTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Rs. 3000'), findsOneWidget);
      expect(find.text('Settle'), findsOneWidget);

      await tester.tap(find.text('Settle'));
      expect(tapped, isTrue);
    });
  });
}
