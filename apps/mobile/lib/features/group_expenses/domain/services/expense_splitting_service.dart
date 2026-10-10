import '../models/split_type.dart';

/// Pure domain service responsible for integer-based financial splitting
/// and deterministic remainder allocation without floating-point precision loss.
class ExpenseSplittingService {
  const ExpenseSplittingService();

  /// Calculates individual shares in minor units for [participantMemberIds].
  ///
  /// Guarantees:
  /// 1. Sum of all shares exactly equals [totalAmountMinor].
  /// 2. Remainder is distributed deterministically (+1 unit to the first R members).
  /// 3. Returns map of `memberId -> shareMinor`.
  Map<String, int> calculateEqualSplit({
    required int totalAmountMinor,
    required List<String> participantMemberIds,
  }) {
    if (participantMemberIds.isEmpty) {
      throw ArgumentError(
        'At least one participant is required to split an expense.',
      );
    }
    if (totalAmountMinor <= 0) {
      throw ArgumentError('Expense amount must be strictly greater than 0.');
    }

    final count = participantMemberIds.length;
    final baseShare = totalAmountMinor ~/ count;
    final remainder = totalAmountMinor % count;

    final result = <String, int>{};
    for (var i = 0; i < count; i++) {
      final memberId = participantMemberIds[i];
      // Allocate 1 minor unit to the first [remainder] participants
      final extra = i < remainder ? 1 : 0;
      result[memberId] = baseShare + extra;
    }

    // Sanity check invariant
    final sum = result.values.fold<int>(0, (a, b) => a + b);
    assert(
      sum == totalAmountMinor,
      'Sum of shares ($sum) must equal total ($totalAmountMinor)',
    );

    return result;
  }

  /// Calculates custom amount shares, ensuring the sum matches [totalAmountMinor].
  Map<String, int> validateAndAssignCustomSplit({
    required int totalAmountMinor,
    required Map<String, int> customSharesMinor,
  }) {
    if (customSharesMinor.isEmpty) {
      throw ArgumentError('At least one participant is required.');
    }
    for (final entry in customSharesMinor.entries) {
      if (entry.value < 0) {
        throw ArgumentError('Participant share cannot be negative.');
      }
    }
    final sum = customSharesMinor.values.fold<int>(0, (a, b) => a + b);
    if (sum != totalAmountMinor) {
      throw ArgumentError(
        'Sum of custom shares ($sum) does not match total amount ($totalAmountMinor).',
      );
    }
    return Map.unmodifiable(customSharesMinor);
  }
}
