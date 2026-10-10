import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 7: Record Repayment (Partial or Full Settlement).
class RecordRepaymentScreen extends ConsumerStatefulWidget {
  final String outingId;
  final String? initialFromMemberId;
  final String? initialToMemberId;
  final int? initialAmountMinor;

  const RecordRepaymentScreen({
    super.key,
    required this.outingId,
    this.initialFromMemberId,
    this.initialToMemberId,
    this.initialAmountMinor,
  });

  @override
  ConsumerState<RecordRepaymentScreen> createState() =>
      _RecordRepaymentScreenState();
}

class _RecordRepaymentScreenState extends ConsumerState<RecordRepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _fromMemberId;
  String? _toMemberId;
  DateTime _settlementDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromMemberId = widget.initialFromMemberId;
    _toMemberId = widget.initialToMemberId;
    if (widget.initialAmountMinor != null && widget.initialAmountMinor! > 0) {
      _amountController.text = (widget.initialAmountMinor! / 100)
          .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _recordSettlement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromMemberId == null || _toMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both payer and receiver.')),
      );
      return;
    }

    if (_fromMemberId == _toMemberId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payer and receiver cannot be the same person.'),
        ),
      );
      return;
    }

    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repayment amount must be greater than zero.'),
        ),
      );
      return;
    }
    final amountMinor = (rawAmount * 100).round();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupExpensesRepositoryProvider);
      await repo.recordSettlement(
        outingId: widget.outingId,
        fromMemberId: _fromMemberId!,
        toMemberId: _toMemberId!,
        amountMinor: amountMinor,
        settlementDate: _settlementDate,
        note: _noteController.text.trim(),
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repayment recorded successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording repayment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(
      outingMembersStreamProvider(widget.outingId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Record Repayment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.length < 2) {
            return const Center(
              child: Text('At least 2 members are required to settle up.'),
            );
          }

          _fromMemberId ??= members.last.id;
          _toMemberId ??= members.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primaryIndigo,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Record when a friend returns money owed. This updates net balances without altering the total outing budget or expense total.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // From (Payer)
                DropdownButtonFormField<String>(
                  initialValue: _fromMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Paid By (Friend returning money) *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.displayName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _fromMemberId = val),
                ),
                const SizedBox(height: 16),

                // To (Receiver)
                DropdownButtonFormField<String>(
                  initialValue: _toMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Received By (Friend receiving money) *',
                    prefixIcon: Icon(Icons.person_pin_outlined),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.displayName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _toMemberId = val),
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repayment Amount *',
                    prefixText: 'Rs. ',
                    hintText: '1000',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter repayment amount';
                    }
                    if ((double.tryParse(val) ?? 0) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _settlementDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _settlementDate = picked);
                    }
                  },
                  borderRadius: AppRadius.cardRadius,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('MMM d, yyyy').format(_settlementDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer / Online'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g. Paid via online transfer or cash return',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _recordSettlement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.cardRadius,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Repayment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
