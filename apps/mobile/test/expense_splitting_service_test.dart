import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/group_expenses/domain/services/expense_splitting_service.dart';

void main() {
  const service = ExpenseSplittingService();

  group('ExpenseSplittingService Unit Tests', () {
    test('Splits evenly across 4 participants (Saturday Beach Trip Lunch)', () {
      final participants = [
        'user_you',
        'user_arun',
        'user_nimal',
        'user_kavin',
      ];
      const totalAmountMinor = 600000; // Rs. 6,000.00

      final shares = service.calculateEqualSplit(
        totalAmountMinor: totalAmountMinor,
        participantMemberIds: participants,
      );

      expect(shares.length, 4);
      expect(shares['user_you'], 150000); // Rs. 1,500.00
      expect(shares['user_arun'], 150000);
      expect(shares['user_nimal'], 150000);
      expect(shares['user_kavin'], 150000);

      final sum = shares.values.fold<int>(0, (a, b) => a + b);
      expect(sum, totalAmountMinor);
    });

    test(
      'Splits with deterministic rounding remainder (Rs. 1,000 across 3 members)',
      () {
        final participants = ['member_a', 'member_b', 'member_c'];
        const totalAmountMinor = 100000; // Rs. 1,000.00

        final shares = service.calculateEqualSplit(
          totalAmountMinor: totalAmountMinor,
          participantMemberIds: participants,
        );

        expect(shares.length, 3);
        // 100,000 / 3 = 33,333 remainder 1.
        // First member receives the extra 1 minor unit.
        expect(shares['member_a'], 33334); // Rs. 333.34
        expect(shares['member_b'], 33333); // Rs. 333.33
        expect(shares['member_c'], 33333); // Rs. 333.33

        final sum = shares.values.fold<int>(0, (a, b) => a + b);
        expect(sum, totalAmountMinor);
      },
    );

    test(
      'Splits for selected participants only (Movie Tickets Rs. 3,000 among 3 of 4)',
      () {
        final selectedParticipants = ['user_you', 'user_arun', 'user_nimal'];
        const totalAmountMinor = 300000; // Rs. 3,000.00

        final shares = service.calculateEqualSplit(
          totalAmountMinor: totalAmountMinor,
          participantMemberIds: selectedParticipants,
        );

        expect(shares.length, 3);
        expect(shares['user_you'], 100000);
        expect(shares['user_arun'], 100000);
        expect(shares['user_nimal'], 100000);
        expect(shares.containsKey('user_kavin'), isFalse);
      },
    );

    test('Throws ArgumentError on non-positive total amount', () {
      expect(
        () => service.calculateEqualSplit(
          totalAmountMinor: 0,
          participantMemberIds: ['user_you'],
        ),
        throwsArgumentError,
      );

      expect(
        () => service.calculateEqualSplit(
          totalAmountMinor: -500,
          participantMemberIds: ['user_you'],
        ),
        throwsArgumentError,
      );
    });

    test('Throws ArgumentError on empty participants list', () {
      expect(
        () => service.calculateEqualSplit(
          totalAmountMinor: 10000,
          participantMemberIds: [],
        ),
        throwsArgumentError,
      );
    });

    test('Validates custom split matching total amount exactly', () {
      final customShares = {
        'member_a': 50000,
        'member_b': 30000,
        'member_c': 20000,
      };

      final validated = service.validateAndAssignCustomSplit(
        totalAmountMinor: 100000,
        customSharesMinor: customShares,
      );

      expect(validated, equals(customShares));
    });

    test('Rejects custom split with mismatched sum', () {
      final customShares = {
        'member_a': 50000,
        'member_b': 30000,
        'member_c': 10000, // Sum = 90,000 != 100,000
      };

      expect(
        () => service.validateAndAssignCustomSplit(
          totalAmountMinor: 100000,
          customSharesMinor: customShares,
        ),
        throwsArgumentError,
      );
    });
  });
}
