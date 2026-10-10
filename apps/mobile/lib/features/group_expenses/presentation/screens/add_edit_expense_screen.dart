import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/services/expense_splitting_service.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 5: Add or Edit Expense with Member Split Selectors.
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String outingId;
  final String? expenseId;

  const AddEditExpenseScreen({
    super.key,
    required this.outingId,
    this.expenseId,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'food';
  String? _selectedPayerId;
  DateTime _expenseDate = DateTime.now();
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;
  bool _isInit = true;

  bool get isEditing => widget.expenseId != null;

  final List<String> _categories = [
    'food',
    'transport',
    'tickets',
    'shopping',
    'accommodation',
    'entertainment',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadExistingExpense(dynamic expenseWithShares) {
    if (expenseWithShares != null && _isInit) {
      _titleController.text = expenseWithShares.expense.title;
      _amountController.text = (expenseWithShares.expense.amountMinor / 100)
          .toStringAsFixed(0);
      _descriptionController.text = expenseWithShares.expense.description;
      _category = expenseWithShares.expense.category;
      _selectedPayerId = expenseWithShares.expense.payerMemberId;
      _expenseDate = expenseWithShares.expense.expenseDate;
      _selectedMemberIds.clear();
      for (final s in expenseWithShares.shares) {
        _selectedMemberIds.add(s.memberId);
      }
      _isInit = false;
    }
  }

  Future<void> _saveExpense(List<dynamic> members) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend to split with.'),
        ),
      );
      return;
    }

    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero.')),
      );
      return;
    }
    final amountMinor = (rawAmount * 100).round();

    // Use pure splitting engine with integer arithmetic
    const splittingService = ExpenseSplittingService();
    final calculatedShares = splittingService.calculateEqualSplit(
      totalAmountMinor: amountMinor,
      participantMemberIds: _selectedMemberIds.toList(),
    );

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupExpensesRepositoryProvider);
      final payerId = _selectedPayerId ?? members.first.id;

      if (isEditing) {
        await repo.updateExpense(
          expenseId: widget.expenseId!,
          payerMemberId: payerId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          amountMinor: amountMinor,
          expenseDate: _expenseDate,
          memberSharesMinor: calculatedShares,
        );
      } else {
        await repo.createExpense(
          outingId: widget.outingId,
          payerMemberId: payerId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          amountMinor: amountMinor,
          expenseDate: _expenseDate,
          memberSharesMinor: calculatedShares,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
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

    if (isEditing) {
      final existingExpenseAsync = ref.watch(
        expenseDetailStreamProvider(widget.expenseId!),
      );
      existingExpenseAsync.whenData((exp) => _loadExistingExpense(exp));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(
              child: Text('No members found for this outing.'),
            );
          }

          if (_selectedPayerId == null) {
            // Default payer is the organizer ("You")
            final organizer = members.firstWhere(
              (m) => m.isOrganizer,
              orElse: () => members.first,
            );
            _selectedPayerId = organizer.id;
          }

          if (_isInit && !isEditing) {
            // By default, select all participants
            _selectedMemberIds.addAll(members.map((m) => m.id));
            _isInit = false;
          }

          // Calculate preview share
          final rawAmount =
              double.tryParse(_amountController.text.trim()) ?? 0.0;
          final count = _selectedMemberIds.length;
          final sharePreview = count > 0 ? (rawAmount / count) : 0.0;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title *',
                    hintText: 'e.g. Lunch, Transport, Movie Tickets',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount & Date Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixText: 'Rs. ',
                          hintText: '6000',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter amount';
                          }
                          if ((double.tryParse(val) ?? 0) <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expenseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _expenseDate = picked);
                          }
                        },
                        borderRadius: AppRadius.cardRadius,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            DateFormat('MMM d').format(_expenseDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Paid By Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPayerId,
                  decoration: const InputDecoration(
                    labelText: 'Paid By',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  items: members.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(
                        m.isOrganizer
                            ? '${m.displayName} (You)'
                            : m.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPayerId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Category Chips Selector
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _category == cat;
                    return ChoiceChip(
                      label: Text(
                        cat.substring(0, 1).toUpperCase() + cat.substring(1),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryIndigo.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primaryIndigo : null,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Description (Optional)',
                    hintText: 'Add details or restaurant name...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Split Between Participants Checklist
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Split Between',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedMemberIds.length == members.length) {
                            _selectedMemberIds.clear();
                          } else {
                            _selectedMemberIds.addAll(members.map((m) => m.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedMemberIds.length == members.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Equal Split Preview Box
                if (rawAmount > 0 && count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                        color: AppColors.primaryIndigo.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Equal Share ($count friends):',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                        Text(
                          'Rs. ${sharePreview.toStringAsFixed(sharePreview % 1 == 0 ? 0 : 2)} each',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checklist Tiles
                for (final m in members)
                  CheckboxListTile(
                    value: _selectedMemberIds.contains(m.id),
                    title: Text(
                      m.isOrganizer
                          ? '${m.displayName} (Organizer)'
                          : m.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    secondary: CircleAvatar(
                      radius: 16,
                      backgroundColor: m.isOrganizer
                          ? AppColors.primaryIndigo
                          : AppColors.secondaryViolet,
                      child: Text(
                        m.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    activeColor: AppColors.primaryIndigo,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedMemberIds.add(m.id);
                        } else {
                          _selectedMemberIds.remove(m.id);
                        }
                      });
                    },
                  ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveExpense(members),
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
                      : Text(
                          isEditing ? 'Save Expense' : 'Add Expense',
                          style: const TextStyle(
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
