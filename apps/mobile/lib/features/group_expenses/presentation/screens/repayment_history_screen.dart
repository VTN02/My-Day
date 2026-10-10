import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 8: Repayment History & Audit Ledger.
class RepaymentHistoryScreen extends ConsumerWidget {
  final String outingId;

  const RepaymentHistoryScreen({super.key, required this.outingId});

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  Future<void> _reverseSettlement(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reverse Repayment?'),
        content: const Text(
          'This will mark this repayment as reversed and restore the debt back to the participant balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reverse'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(groupExpensesRepositoryProvider)
          .reverseSettlement(settlementId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Repayment reversed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settlementsAsync = ref.watch(
      outingSettlementsStreamProvider(outingId),
    );
    final membersAsync = ref.watch(outingMembersStreamProvider(outingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Repayment History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: settlementsAsync.when(
        data: (settlements) {
          if (settlements.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No repayments recorded yet',
              message:
                  'When friends return money owed, record settlements to maintain an audit trail.',
            );
          }

          return membersAsync.when(
            data: (members) {
              final memberNames = {
                for (final m in members) m.id: m.displayName,
              };

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: settlements.length,
                itemBuilder: (context, index) {
                  final st = settlements[index];
                  final fromName =
                      memberNames[st.fromMemberId] ?? 'Participant';
                  final toName = memberNames[st.toMemberId] ?? 'Participant';
                  final isReversed = st.status == 'reversed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardSurface
                          : AppColors.lightCardSurface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isReversed
                                        ? AppColors.errorCoral.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.successMint.withValues(
                                            alpha: 0.15,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isReversed
                                        ? Icons.undo_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 18,
                                    color: isReversed
                                        ? AppColors.errorCoral
                                        : AppColors.successMint,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$fromName → $toName',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy',
                                      ).format(st.settlementDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.lightSecondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(st.amountMinor),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    decoration: isReversed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isReversed
                                        ? (isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.lightSecondaryText)
                                        : AppColors.successMint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  st.paymentMethod.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (st.note.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              st.note,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                        if (!isReversed) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _reverseSettlement(context, ref, st.id),
                              icon: const Icon(
                                Icons.undo_rounded,
                                size: 14,
                                color: AppColors.errorCoral,
                              ),
                              label: const Text(
                                'Reverse Payment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.errorCoral,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
