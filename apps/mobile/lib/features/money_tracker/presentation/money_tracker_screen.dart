import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_card.dart';

/// Money Tracker Screen for managing Borrowed and Lent money with repayment tracking.
class MoneyTrackerScreen extends ConsumerStatefulWidget {
  const MoneyTrackerScreen({super.key});

  @override
  ConsumerState<MoneyTrackerScreen> createState() => _MoneyTrackerScreenState();
}

class _MoneyTrackerScreenState extends ConsumerState<MoneyTrackerScreen> {
  String _selectedFilter = 'All'; // 'All', 'Lent', 'Borrowed', 'Overdue', 'Settled'

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
  }

  void _showAddDebtDialog() {
    String type = 'lent'; // 'lent' or 'borrowed'
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime issueDate = DateTime.now();
    DateTime? dueDate;
    String? selectedAccount = 'account_cash';
    bool updateAccountBalance = false;
    bool reminderEnabled = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type == 'lent' ? 'Record Lent Money' : 'Record Borrowed Money',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type toggle
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                            label: const Text('I Lent Money'),
                            onPressed: () => setModalState(() => type = 'lent'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: type == 'lent'
                                  ? (isDark
                                      ? AppColors.darkSoftMint
                                      : AppColors.lightSoftMint)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: type == 'lent'
                                    ? AppColors.successMint
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                              foregroundColor: type == 'lent'
                                  ? AppColors.successMint
                                  : (isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            label: const Text('I Borrowed'),
                            onPressed: () => setModalState(() => type = 'borrowed'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: type == 'borrowed'
                                  ? (isDark
                                      ? AppColors.darkSoftCoral
                                      : AppColors.lightSoftCoral)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: type == 'borrowed'
                                    ? AppColors.errorCoral
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                              foregroundColor: type == 'borrowed'
                                  ? AppColors.errorCoral
                                  : (isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: type == 'lent' ? "Borrower's Name" : "Lender's Name",
                      hint: 'e.g. Kasun Perera, Kamal, Amma',
                      controller: personController,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Amount (LKR)',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: amountController,
                    ),
                    const SizedBox(height: 14),

                    // Due Date Picker
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                                label: Text(
                                  dueDate != null
                                      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                                      : 'Set Deadline',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(() => dueDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        if (dueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModalState(() => dueDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Linked Account
                    Row(
                      children: [
                        Checkbox(
                          value: updateAccountBalance,
                          activeColor: AppColors.primaryIndigo,
                          onChanged: (val) =>
                              setModalState(() => updateAccountBalance = val ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                                () => updateAccountBalance = !updateAccountBalance),
                            child: Text(
                              type == 'lent'
                                  ? 'Deduct from liquid account balance'
                                  : 'Deposit into liquid account balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (updateAccountBalance) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: selectedAccount == 'account_cash',
                            selectedColor: AppColors.primaryIndigo,
                            onSelected: (_) =>
                                setModalState(() => selectedAccount = 'account_cash'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Card'),
                            selected: selectedAccount == 'account_card',
                            selectedColor: AppColors.primaryIndigo,
                            onSelected: (_) =>
                                setModalState(() => selectedAccount = 'account_card'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Description / Reason',
                      hint: 'e.g. Urgent loan for exam fees, Trip share',
                      controller: descController,
                    ),
                    const SizedBox(height: 14),

                    // Reminder toggle
                    if (dueDate != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enable Repayment Reminder',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          Switch(
                            value: reminderEnabled,
                            activeThumbColor: AppColors.primaryIndigo,
                            onChanged: (v) => setModalState(() => reminderEnabled = v),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: type == 'lent' ? 'Save Lent Record' : 'Save Borrowed Record',
                      backgroundColor: type == 'lent'
                          ? AppColors.successMint
                          : AppColors.errorCoral,
                      isFullWidth: true,
                      onPressed: () async {
                        final person = personController.text.trim();
                        final raw = double.tryParse(amountController.text.trim()) ?? 0;
                        if (person.isEmpty || raw <= 0) return;

                        final amountCents = (raw * 100).round();
                        final desc = descController.text.trim();

                        final debtId = await ref
                            .read(moneyTrackerRepositoryProvider)
                            .createDebt(
                              type: type,
                              personName: person,
                              initialAmountCents: amountCents,
                              issueDate: issueDate,
                              dueDate: dueDate,
                              description: desc.isNotEmpty ? desc : null,
                              reminderEnabled: reminderEnabled,
                              linkedAccountId:
                                  updateAccountBalance ? selectedAccount : null,
                              updateAccountBalance: updateAccountBalance,
                            );

                        // Schedule reminder if configured
                        if (reminderEnabled && dueDate != null) {
                          final notifId = debtId.hashCode;
                          await NotificationService().scheduleDebtReminder(
                            id: notifId,
                            personName: person,
                            amountCents: amountCents,
                            isLent: type == 'lent',
                            scheduledDate: DateTime(
                              dueDate!.year,
                              dueDate!.month,
                              dueDate!.day,
                              9,
                              0,
                            ),
                            description: desc,
                          );
                        }

                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordRepaymentDialog(MoneyDebtEntry debt) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime repaymentDate = DateTime.now();
    String? selectedAccount = 'account_cash';
    bool updateAccountBalance = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isLent = debt.type.toLowerCase() == 'lent';
            final remainingCents = debt.remainingAmountCents;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isLent ? 'Log Repayment Received' : 'Log Repayment Made',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Person: ${debt.personName} • Balance: ${_formatCents(remainingCents)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Repayment Amount (LKR)',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: amountController,
                    ),
                    const SizedBox(height: 8),

                    // Quick fill chips
                    Row(
                      children: [
                        ActionChip(
                          label: Text('Full (${_formatCents(remainingCents)})'),
                          onPressed: () {
                            setModalState(() {
                              amountController.text =
                                  (remainingCents / 100.0).toStringAsFixed(0);
                            });
                          },
                        ),
                        if (remainingCents > 10000) ...[
                          const SizedBox(width: 8),
                          ActionChip(
                            label: Text('Half (${_formatCents(remainingCents ~/ 2)})'),
                            onPressed: () {
                              setModalState(() {
                                amountController.text =
                                    ((remainingCents ~/ 2) / 100.0).toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Update account balance
                    Row(
                      children: [
                        Checkbox(
                          value: updateAccountBalance,
                          activeColor: AppColors.primaryIndigo,
                          onChanged: (val) =>
                              setModalState(() => updateAccountBalance = val ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                                () => updateAccountBalance = !updateAccountBalance),
                            child: Text(
                              isLent
                                  ? 'Deposit payment into liquid account'
                                  : 'Deduct payment from liquid account',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (updateAccountBalance) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: selectedAccount == 'account_cash',
                            selectedColor: AppColors.primaryIndigo,
                            onSelected: (_) =>
                                setModalState(() => selectedAccount = 'account_cash'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Card'),
                            selected: selectedAccount == 'account_card',
                            selectedColor: AppColors.primaryIndigo,
                            onSelected: (_) =>
                                setModalState(() => selectedAccount = 'account_card'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Notes / Memo (Optional)',
                      hint: 'e.g. Paid via Bank Transfer, Cash handed over',
                      controller: notesController,
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: 'Confirm Repayment',
                      backgroundColor: AppColors.successMint,
                      isFullWidth: true,
                      onPressed: () async {
                        final raw = double.tryParse(amountController.text.trim()) ?? 0;
                        if (raw <= 0) return;

                        final amountCents = (raw * 100).round();
                        final notes = notesController.text.trim();

                        await ref
                            .read(moneyTrackerRepositoryProvider)
                            .recordRepayment(
                              debtId: debt.id,
                              amountCents: amountCents,
                              repaymentDate: repaymentDate,
                              notes: notes.isNotEmpty ? notes : null,
                              linkedAccountId:
                                  updateAccountBalance ? selectedAccount : null,
                              updateAccountBalance: updateAccountBalance,
                            );

                        final newRemaining =
                            (remainingCents - amountCents).clamp(0, debt.initialAmountCents);

                        // Trigger notification
                        await NotificationService().showDebtRepaymentNotification(
                          id: debt.id.hashCode,
                          personName: debt.personName,
                          amountCents: amountCents,
                          remainingCents: newRemaining,
                          isLent: isLent,
                          isSettled: newRemaining == 0,
                        );

                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRepaymentHistoryDialog(MoneyDebtEntry debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Consumer(
          builder: (context, ref, _) {
            final repaymentsAsync = ref.watch(debtRepaymentsStreamProvider(debt.id));

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repayment History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${debt.personName} (${debt.type.toUpperCase()})',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary row
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Initial Loan',
                          value: _formatCents(debt.initialAmountCents),
                          subtitle: 'Principal',
                          icon: Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Remaining',
                          value: _formatCents(debt.remainingAmountCents),
                          subtitle: debt.remainingAmountCents == 0 ? 'Settled' : 'Active',
                          icon: Icons.hourglass_bottom_outlined,
                          iconColor: debt.remainingAmountCents == 0
                              ? AppColors.successMint
                              : AppColors.errorCoral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Repayment Timeline',
                    subtitle: 'Audit log of returned funds',
                  ),
                  Expanded(
                    child: repaymentsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                      data: (repayments) {
                        if (repayments.isEmpty) {
                          return Center(
                            child: Text(
                              'No repayments logged yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: repayments.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final r = repayments[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFD1FAE5),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.successMint,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _formatCents(r.amountCents),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                '${r.repaymentDate.day}/${r.repaymentDate.month}/${r.repaymentDate.year}${r.notes != null ? " • ${r.notes}" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final debtsAsync = ref.watch(allDebtsStreamProvider);
    final summaryAsync = ref.watch(moneyTrackerSummaryStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverGradientHeader(
            eyebrow: 'Borrowed & Lent',
            title: 'Money Tracker',
            subtitle: 'Track receivables, payables, and repayment deadlines',
            gradient: AppGradients.finance,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (summary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Net Position
                      SummaryCard(
                        title: summary.netBalanceCents >= 0
                            ? 'Net Receivable Position'
                            : 'Net Payable Position',
                        value: _formatCents(summary.netBalanceCents.abs()),
                        subtitle: summary.netBalanceCents >= 0
                            ? 'Overall, you are owed more than you owe'
                            : 'Overall, you owe more than you are owed',
                        icon: summary.netBalanceCents >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        iconColor: summary.netBalanceCents >= 0
                            ? AppColors.successMint
                            : AppColors.errorCoral,
                        iconBackgroundColor: summary.netBalanceCents >= 0
                            ? (isDark
                                ? AppColors.darkSoftMint
                                : AppColors.lightSoftMint)
                            : (isDark
                                ? AppColors.darkSoftCoral
                                : AppColors.lightSoftCoral),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'You are Owed',
                              value: _formatCents(summary.totalLentRemainingCents),
                              subtitle: '${summary.activeLentCount} active loans',
                              icon: Icons.arrow_outward_rounded,
                              iconColor: AppColors.successMint,
                              iconBackgroundColor: isDark
                                  ? AppColors.darkSoftMint
                                  : AppColors.lightSoftMint,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'You Owe',
                              value: _formatCents(summary.totalBorrowedRemainingCents),
                              subtitle: '${summary.activeBorrowedCount} active debts',
                              icon: Icons.arrow_downward_rounded,
                              iconColor: AppColors.errorCoral,
                              iconBackgroundColor: isDark
                                  ? AppColors.darkSoftCoral
                                  : AppColors.lightSoftCoral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'All',
                            'Lent',
                            'Borrowed',
                            'Overdue',
                            'Settled',
                          ].map((f) {
                            final isSel = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: isSel,
                                selectedColor: isDark
                                    ? AppColors.darkSoftIndigo
                                    : AppColors.lightSoftIndigo,
                                checkmarkColor: AppColors.primaryIndigo,
                                labelStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel
                                      ? AppColors.primaryIndigo
                                      : (isDark
                                          ? AppColors.darkPrimaryText
                                          : AppColors.lightPrimaryText),
                                ),
                                onSelected: (_) => setState(() => _selectedFilter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ),
          debtsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: LoadingState(message: 'Loading money tracking records...'),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error: $err')),
              ),
            ),
            data: (debts) {
              final now = DateTime.now();

              // Filter
              final filtered = debts.where((d) {
                final isSettled = d.remainingAmountCents <= 0;
                final isOverdue = d.dueDate != null && now.isAfter(d.dueDate!) && !isSettled;

                if (_selectedFilter == 'Lent') {
                  return d.type.toLowerCase() == 'lent' && !isSettled;
                } else if (_selectedFilter == 'Borrowed') {
                  return d.type.toLowerCase() == 'borrowed' && !isSettled;
                } else if (_selectedFilter == 'Overdue') {
                  return isOverdue;
                } else if (_selectedFilter == 'Settled') {
                  return isSettled;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyState(
                      icon: Icons.handshake_outlined,
                      title: 'No debt records found',
                      message:
                          'Track money you lend to friends or money you borrow to stay on top of obligations.',
                      actionLabel: 'Record New Debt',
                      onActionPressed: () => _showAddDebtDialog(),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final debt = filtered[index];
                      final isLent = debt.type.toLowerCase() == 'lent';
                      final isSettled = debt.remainingAmountCents <= 0;
                      final isOverdue = debt.dueDate != null &&
                          now.isAfter(debt.dueDate!) &&
                          !isSettled;

                      final repaidCents =
                          debt.initialAmountCents - debt.remainingAmountCents;
                      final progress = debt.initialAmountCents > 0
                          ? (repaidCents / debt.initialAmountCents).clamp(0.0, 1.0)
                          : 1.0;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardSurface
                              : AppColors.lightCardSurface,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isOverdue
                                ? AppColors.errorCoral.withValues(alpha: 0.6)
                                : isSettled
                                    ? (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    : (isLent
                                        ? AppColors.successMint.withValues(alpha: 0.4)
                                        : AppColors.errorCoral.withValues(alpha: 0.4)),
                            width: isOverdue ? 1.5 : 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isLent
                                          ? (isDark
                                              ? AppColors.darkSoftMint
                                              : AppColors.lightSoftMint)
                                          : (isDark
                                              ? AppColors.darkSoftCoral
                                              : AppColors.lightSoftCoral),
                                      child: Icon(
                                        isLent
                                            ? Icons.arrow_outward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 18,
                                        color: isLent
                                            ? AppColors.successMint
                                            : AppColors.errorCoral,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt.personName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkPrimaryText
                                                : AppColors.lightPrimaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isLent
                                              ? 'Lent to person'
                                              : 'Borrowed from person',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.darkSecondaryText
                                                : AppColors.lightSecondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSettled
                                            ? Colors.grey.withValues(alpha: 0.15)
                                            : isOverdue
                                                ? AppColors.errorCoral
                                                    .withValues(alpha: 0.15)
                                                : isLent
                                                    ? AppColors.successMint
                                                        .withValues(alpha: 0.15)
                                                    : AppColors.errorCoral
                                                        .withValues(alpha: 0.15),
                                        borderRadius: AppRadius.pillRadius,
                                      ),
                                      child: Text(
                                        isSettled
                                            ? 'SETTLED'
                                            : isOverdue
                                                ? 'OVERDUE'
                                                : debt.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSettled
                                              ? Colors.grey
                                              : isOverdue
                                                  ? AppColors.errorCoral
                                                  : isLent
                                                      ? AppColors.successMint
                                                      : AppColors.errorCoral,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.lightSecondaryText,
                                      ),
                                      onSelected: (act) async {
                                        if (act == 'repay') {
                                          _showRecordRepaymentDialog(debt);
                                        } else if (act == 'history') {
                                          _showRepaymentHistoryDialog(debt);
                                        } else if (act == 'delete') {
                                          await ref
                                              .read(moneyTrackerRepositoryProvider)
                                              .deleteDebt(debt.id);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        if (!isSettled)
                                          PopupMenuItem(
                                            value: 'repay',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.payment_outlined, size: 18),
                                                SizedBox(width: 8),
                                                Text('Record Repayment'),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'history',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.history_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Repayment History'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.delete_outline,
                                                  size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete Record',
                                                  style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining: ${_formatCents(debt.remainingAmountCents)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSettled
                                        ? AppColors.successMint
                                        : isLent
                                            ? AppColors.successMint
                                            : AppColors.errorCoral,
                                  ),
                                ),
                                Text(
                                  'Initial: ${_formatCents(debt.initialAmountCents)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ClipRRect(
                              borderRadius: AppRadius.pillRadius,
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                valueColor: AlwaysStoppedAnimation(
                                  isSettled
                                      ? AppColors.successMint
                                      : isLent
                                          ? AppColors.successMint
                                          : AppColors.errorCoral,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (debt.dueDate != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_outlined,
                                        size: 14,
                                        color: isOverdue
                                            ? AppColors.errorCoral
                                            : (isDark
                                                ? AppColors.darkSecondaryText
                                                : AppColors.lightSecondaryText),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOverdue
                                            ? 'Overdue since ${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}'
                                            : 'Due ${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isOverdue
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isOverdue
                                              ? AppColors.errorCoral
                                              : (isDark
                                                  ? AppColors.darkSecondaryText
                                                  : AppColors.lightSecondaryText),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'No fixed due date',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                                  ),
                                if (!isSettled)
                                  TextButton(
                                    onPressed: () => _showRecordRepaymentDialog(debt),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Log Repayment',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  )
                                else
                                  TextButton(
                                    onPressed: () => _showRepaymentHistoryDialog(debt),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View History',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('New Debt / Loan'),
        onPressed: () => _showAddDebtDialog(),
      ),
    );
  }
}
