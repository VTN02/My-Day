import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 3: Create or Edit Outing Screen.
class CreateEditOutingScreen extends ConsumerStatefulWidget {
  final String? outingId;

  const CreateEditOutingScreen({super.key, this.outingId});

  @override
  ConsumerState<CreateEditOutingScreen> createState() =>
      _CreateEditOutingScreenState();
}

class _CreateEditOutingScreenState
    extends ConsumerState<CreateEditOutingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _friendController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'LKR';
  String _status = 'active';
  final List<String> _friends = [];
  bool _isLoading = false;

  bool get isEditing => widget.outingId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final repo = ref.read(groupExpensesRepositoryProvider);
    final outing = await repo.getOuting(widget.outingId!);
    if (outing != null && mounted) {
      _titleController.text = outing.title;
      _descriptionController.text = outing.description;
      _budgetController.text = (outing.budgetMinor / 100).toStringAsFixed(0);
      _selectedDate = outing.outingDate;
      _selectedCurrency = outing.currencyCode;
      _status = outing.status;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _friendController.dispose();
    super.dispose();
  }

  void _addFriend() {
    final name = _friendController.text.trim();
    if (name.isEmpty) return;

    if (name.toLowerCase() == 'you') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('"You" is already included as the organizer.'),
        ),
      );
      return;
    }

    if (_friends.any((f) => f.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant already added.')),
      );
      return;
    }

    setState(() {
      _friends.add(name);
      _friendController.clear();
    });
  }

  Future<void> _saveOuting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(groupExpensesRepositoryProvider);
      final rawBudget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      final budgetMinor = (rawBudget * 100).round();

      if (isEditing) {
        await repo.updateOuting(
          outingId: widget.outingId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          outingDate: _selectedDate,
          budgetMinor: budgetMinor,
          currencyCode: _selectedCurrency,
          status: _status,
        );
        if (mounted) {
          context.pop();
        }
      } else {
        final newOuting = await repo.createOuting(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          outingDate: _selectedDate,
          budgetMinor: budgetMinor,
          currencyCode: _selectedCurrency,
          initialMemberNames: _friends,
        );
        if (mounted) {
          context.pushReplacement('/split/${newOuting.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving outing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Outing' : 'Create Outing',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Outing Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Outing Name *',
                hintText: 'e.g. Saturday Beach Trip, Dinner, Road Trip',
                prefixIcon: Icon(Icons.celebration_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an outing name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date & Budget Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: AppRadius.cardRadius,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Day Budget',
                      prefixText: 'Rs. ',
                      hintText: '20000',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes, plan details, or destinations...',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Friends Section (Only when creating)
            if (!isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Friends Attending',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_friends.length + 1} participants',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"You" are automatically included as the organizer. Add other friends attending below:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 12),

              // Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const CircleAvatar(
                      backgroundColor: AppColors.primaryIndigo,
                      child: Text(
                        'Y',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    label: const Text(
                      'You (Organizer)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primaryIndigo.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  for (final friend in _friends)
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: AppColors.secondaryViolet,
                        child: Text(
                          friend.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      label: Text(friend),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _friends.remove(friend)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Add Friend Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _friendController,
                      decoration: const InputDecoration(
                        hintText: 'Enter friend name (e.g. Arun, Nimal)',
                        prefixIcon: Icon(Icons.person_add_alt_outlined),
                      ),
                      onSubmitted: (_) => _addFriend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addFriend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.cardRadius,
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Save / Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveOuting,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius,
                ),
                elevation: 0,
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
                      isEditing ? 'Save Changes' : 'Create Outing',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
