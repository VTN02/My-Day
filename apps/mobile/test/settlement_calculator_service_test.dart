import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/group_expenses/domain/services/settlement_calculator_service.dart';

void main() {
  const service = SettlementCalculatorService();

  final memberYou = OutingMemberEntry(
    id: 'm_you',
    outingId: 'outing_beach',
    displayName: 'You',
    isOrganizer: true,
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final memberArun = OutingMemberEntry(
    id: 'm_arun',
    outingId: 'outing_beach',
    displayName: 'Arun',
    isOrganizer: false,
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final memberNimal = OutingMemberEntry(
    id: 'm_nimal',
    outingId: 'outing_beach',
    displayName: 'Nimal',
    isOrganizer: false,
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final memberKavin = OutingMemberEntry(
    id: 'm_kavin',
    outingId: 'outing_beach',
    displayName: 'Kavin',
    isOrganizer: false,
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final allMembers = [memberYou, memberArun, memberNimal, memberKavin];

  // Expenses: Lunch (6000 by You), Transport (4000 by Arun), Snacks (2000 by Nimal)
  final expenseLunch = OutingExpenseEntry(
    id: 'e_lunch',
    outingId: 'outing_beach',
    payerMemberId: 'm_you',
    title: 'Lunch',
    description: '',
    category: 'food',
    amountMinor: 600000,
    expenseDate: DateTime(2026, 10, 10, 12, 30),
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final expenseTransport = OutingExpenseEntry(
    id: 'e_transport',
    outingId: 'outing_beach',
    payerMemberId: 'm_arun',
    title: 'Transport',
    description: '',
    category: 'transport',
    amountMinor: 400000,
    expenseDate: DateTime(2026, 10, 10, 9, 0),
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final expenseSnacks = OutingExpenseEntry(
    id: 'e_snacks',
    outingId: 'outing_beach',
    payerMemberId: 'm_nimal',
    title: 'Snacks',
    description: '',
    category: 'food',
    amountMinor: 200000,
    expenseDate: DateTime(2026, 10, 10, 16, 0),
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  final allExpenses = [expenseLunch, expenseTransport, expenseSnacks];

  // Shares: each expense split equally among all 4 members
  // Lunch: 150000 each (600000 total)
  // Transport: 100000 each (400000 total)
  // Snacks: 50000 each (200000 total)
  final allShares = <OutingExpenseShareEntry>[
    // Lunch shares
    for (final m in allMembers)
      OutingExpenseShareEntry(
        id: 's_l_${m.id}',
        expenseId: 'e_lunch',
        memberId: m.id,
        amountMinor: 150000,
      ),
    // Transport shares
    for (final m in allMembers)
      OutingExpenseShareEntry(
        id: 's_t_${m.id}',
        expenseId: 'e_transport',
        memberId: m.id,
        amountMinor: 100000,
      ),
    // Snacks shares
    for (final m in allMembers)
      OutingExpenseShareEntry(
        id: 's_s_${m.id}',
        expenseId: 'e_snacks',
        memberId: m.id,
        amountMinor: 50000,
      ),
  ];

  final beachOuting = GroupOutingEntry(
    id: 'outing_beach',
    organizerLocalId: 'm_you',
    title: 'Saturday Beach Trip',
    description: 'Day outing with friends',
    outingDate: DateTime(2026, 10, 10),
    budgetMinor: 2000000, // Rs. 20,000
    currencyCode: 'LKR',
    status: 'active',
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 10),
  );

  group('SettlementCalculatorService — Saturday Beach Trip Scenario', () {
    test('Calculates exact net balances and verifies zero-sum invariant', () {
      final balances = service.calculateMemberBalances(
        members: allMembers,
        activeExpenses: allExpenses,
        activeShares: allShares,
        completedSettlements: const [],
      );

      expect(balances.length, 4);

      final youBalance = balances.firstWhere((b) => b.memberId == 'm_you');
      final arunBalance = balances.firstWhere((b) => b.memberId == 'm_arun');
      final nimalBalance = balances.firstWhere((b) => b.memberId == 'm_nimal');
      final kavinBalance = balances.firstWhere((b) => b.memberId == 'm_kavin');

      // You: Paid 600,000, Share 300,000 -> Net +300,000 (Creditor)
      expect(youBalance.totalPaidMinor, 600000);
      expect(youBalance.totalShareMinor, 300000);
      expect(youBalance.netBalanceMinor, 300000);
      expect(youBalance.isCreditor, isTrue);

      // Arun: Paid 400,000, Share 300,000 -> Net +100,000 (Creditor)
      expect(arunBalance.totalPaidMinor, 400000);
      expect(arunBalance.totalShareMinor, 300000);
      expect(arunBalance.netBalanceMinor, 100000);
      expect(arunBalance.isCreditor, isTrue);

      // Nimal: Paid 200,000, Share 300,000 -> Net -100,000 (Debtor)
      expect(nimalBalance.totalPaidMinor, 200000);
      expect(nimalBalance.totalShareMinor, 300000);
      expect(nimalBalance.netBalanceMinor, -100000);
      expect(nimalBalance.isDebtor, isTrue);
      expect(nimalBalance.outstandingDebtMinor, 100000);

      // Kavin: Paid 0, Share 300,000 -> Net -300,000 (Debtor)
      expect(kavinBalance.totalPaidMinor, 0);
      expect(kavinBalance.totalShareMinor, 300000);
      expect(kavinBalance.netBalanceMinor, -300000);
      expect(kavinBalance.isDebtor, isTrue);
      expect(kavinBalance.outstandingDebtMinor, 300000);

      // Total receivable equals total payable
      final totalReceivable = balances
          .where((b) => b.isCreditor)
          .fold<int>(0, (s, b) => s + b.netBalanceMinor);
      final totalPayable = balances
          .where((b) => b.isDebtor)
          .fold<int>(0, (s, b) => s + b.outstandingDebtMinor);
      expect(totalReceivable, 400000);
      expect(totalPayable, 400000);
    });

    test('Computes optimal suggested settlement transfers', () {
      final balances = service.calculateMemberBalances(
        members: allMembers,
        activeExpenses: allExpenses,
        activeShares: allShares,
        completedSettlements: const [],
      );

      final settlements = service.calculateSuggestedSettlements(balances);

      expect(settlements.length, 2);

      // 1. Kavin pays You Rs. 3,000 (300,000 cents)
      expect(settlements[0].fromMemberId, 'm_kavin');
      expect(settlements[0].toMemberId, 'm_you');
      expect(settlements[0].amountMinor, 300000);

      // 2. Nimal pays Arun Rs. 1,000 (100,000 cents)
      expect(settlements[1].fromMemberId, 'm_nimal');
      expect(settlements[1].toMemberId, 'm_arun');
      expect(settlements[1].amountMinor, 100000);
    });

    test('Produces complete OutingSummary with budget calculations', () {
      final summary = service.summarizeOuting(
        outing: beachOuting,
        members: allMembers,
        activeExpenses: allExpenses,
        activeShares: allShares,
        completedSettlements: const [],
      );

      expect(summary.totalSpentMinor, 1200000); // Rs. 12,000
      expect(summary.budgetRemainingMinor, 800000); // Rs. 8,000
      expect(summary.budgetUsageRatio, 0.6); // 60%
      expect(summary.totalSharePerPersonMinor, 300000); // Rs. 3,000
      expect(summary.totalOutstandingDebtMinor, 400000); // Rs. 4,000
    });
  });

  group('SettlementCalculatorService — Partial Repayment Lifecycle', () {
    test('Tracks partial settlement without modifying total outing expense', () {
      // Event 1: Kavin returns Rs. 1,000 (100000 minor units) to You
      final partialSettlement = OutingSettlementEntry(
        id: 'settle_1',
        outingId: 'outing_beach',
        fromMemberId: 'm_kavin',
        toMemberId: 'm_you',
        amountMinor: 100000,
        settlementDate: DateTime(2026, 10, 11),
        note: 'Partial cash repayment',
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime(2026, 10, 11),
        updatedAt: DateTime(2026, 10, 11),
      );

      final balances = service.calculateMemberBalances(
        members: allMembers,
        activeExpenses: allExpenses,
        activeShares: allShares,
        completedSettlements: [partialSettlement],
      );

      final kavin = balances.firstWhere((b) => b.memberId == 'm_kavin');
      final you = balances.firstWhere((b) => b.memberId == 'm_you');

      // Kavin originally owed 300,000; paid 100,000 -> now owes 200,000 (Partially Paid)
      expect(kavin.netBeforeRepaymentsMinor, -300000);
      expect(kavin.repaymentsSentMinor, 100000);
      expect(kavin.netBalanceMinor, -200000);
      expect(kavin.outstandingDebtMinor, 200000);

      // You originally owed to receive 300,000; received 100,000 -> now to receive 200,000
      expect(you.netBeforeRepaymentsMinor, 300000);
      expect(you.repaymentsReceivedMinor, 100000);
      expect(you.netBalanceMinor, 200000);

      // Suggested settlement should now reflect remaining debt of 200,000
      final updatedSuggested = service.calculateSuggestedSettlements(balances);
      final kavinToYou = updatedSuggested.firstWhere(
        (s) => s.fromMemberId == 'm_kavin' && s.toMemberId == 'm_you',
      );
      expect(kavinToYou.amountMinor, 200000);
    });

    test('Full settlement closes obligation completely', () {
      // Event 1 + Event 2: Kavin pays remaining Rs. 2,000 to You
      final settlement1 = OutingSettlementEntry(
        id: 'settle_1',
        outingId: 'outing_beach',
        fromMemberId: 'm_kavin',
        toMemberId: 'm_you',
        amountMinor: 100000,
        settlementDate: DateTime(2026, 10, 11),
        note: 'Partial payment',
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime(2026, 10, 11),
        updatedAt: DateTime(2026, 10, 11),
      );

      final settlement2 = OutingSettlementEntry(
        id: 'settle_2',
        outingId: 'outing_beach',
        fromMemberId: 'm_kavin',
        toMemberId: 'm_you',
        amountMinor: 200000,
        settlementDate: DateTime(2026, 10, 12),
        note: 'Final settlement',
        paymentMethod: 'transfer',
        status: 'completed',
        createdAt: DateTime(2026, 10, 12),
        updatedAt: DateTime(2026, 10, 12),
      );

      // Also Nimal pays Arun 100,000
      final settlement3 = OutingSettlementEntry(
        id: 'settle_3',
        outingId: 'outing_beach',
        fromMemberId: 'm_nimal',
        toMemberId: 'm_arun',
        amountMinor: 100000,
        settlementDate: DateTime(2026, 10, 12),
        note: 'Settled',
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: DateTime(2026, 10, 12),
        updatedAt: DateTime(2026, 10, 12),
      );

      final balances = service.calculateMemberBalances(
        members: allMembers,
        activeExpenses: allExpenses,
        activeShares: allShares,
        completedSettlements: [settlement1, settlement2, settlement3],
      );

      for (final b in balances) {
        expect(b.netBalanceMinor, 0);
        expect(b.isSettled, isTrue);
      }

      final suggested = service.calculateSuggestedSettlements(balances);
      expect(suggested.isEmpty, isTrue);
    });
  });
}
