import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 6: Participant Management Screen.
class MemberManagementScreen extends ConsumerStatefulWidget {
  final String outingId;

  const MemberManagementScreen({super.key, required this.outingId});

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddMemberDialog() async {
    _nameController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter name (e.g. Maya)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ref
                    .read(groupExpensesRepositoryProvider)
                    .addMember(outingId: widget.outingId, displayName: name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(String memberId, String currentName) async {
    _nameController.text = currentName;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Friend Name'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ref
                    .read(groupExpensesRepositoryProvider)
                    .updateMemberName(memberId: memberId, newName: name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMember(String memberId, String name) async {
    final repo = ref.read(groupExpensesRepositoryProvider);
    final canDelete = await repo.canDeleteMember(memberId);

    if (!canDelete) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Remove Friend'),
            content: Text(
              'Cannot remove $name because they are either the organizer or have active expenses, shares, or repayments recorded.\n\nPlease reassign or settle their transactions before removing.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text(
          'Are you sure you want to remove this participant?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteMember(memberId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(
      outingSummaryStreamProvider(widget.outingId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) return const SizedBox.shrink();
          final members = summary.members;
          final balances = {
            for (final b in summary.memberBalances) b.memberId: b,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Participants (${members.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap a member to edit their name. Members with recorded expenses or shares cannot be deleted without first clearing their transactions.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 14),

              for (final m in members) ...[
                Builder(
                  builder: (context) {
                    final b = balances[m.id];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: m.isOrganizer
                                ? AppColors.primaryIndigo
                                : AppColors.secondaryViolet,
                            child: Text(
                              m.displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m.displayName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText,
                                      ),
                                    ),
                                    if (m.isOrganizer) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryIndigo
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Organizer',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryIndigo,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (b != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Paid: Rs. ${(b.totalPaidMinor / 100).toStringAsFixed(0)} • Share: Rs. ${(b.totalShareMinor / 100).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                _showEditNameDialog(m.id, m.displayName),
                          ),
                          if (!m.isOrganizer)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.errorCoral,
                                size: 18,
                              ),
                              onPressed: () =>
                                  _deleteMember(m.id, m.displayName),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add Friend',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
