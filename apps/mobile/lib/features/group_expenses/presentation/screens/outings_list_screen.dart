import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/group_expenses_providers.dart';

/// Screen 2: Outings List screen with Active/Completed/Archived tabs and search.
class OutingsListScreen extends ConsumerStatefulWidget {
  const OutingsListScreen({super.key});

  @override
  ConsumerState<OutingsListScreen> createState() => _OutingsListScreenState();
}

class _OutingsListScreenState extends ConsumerState<OutingsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyDay Split',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryIndigo,
          indicatorWeight: 3,
          labelColor: AppColors.primaryIndigo,
          unselectedLabelColor: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search outings...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightBorder.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.cardRadius,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.cardRadius,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ),

          // Tabs Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OutingListTab(status: 'active', searchQuery: _searchQuery),
                _OutingListTab(status: 'completed', searchQuery: _searchQuery),
                _OutingListTab(status: 'archived', searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/split/create'),
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Outing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _OutingListTab extends ConsumerWidget {
  final String status;
  final String searchQuery;

  const _OutingListTab({required this.status, required this.searchQuery});

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outingsAsync = ref.watch(outingsByStatusStreamProvider(status));

    return outingsAsync.when(
      data: (allOutings) {
        final filtered = searchQuery.isEmpty
            ? allOutings
            : allOutings
                  .where(
                    (o) =>
                        o.title.toLowerCase().contains(searchQuery) ||
                        o.description.toLowerCase().contains(searchQuery),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.groups_outlined,
            title: 'No $status outings',
            message: status == 'active'
                ? 'Plan your next outing with friends and track shared expenses easily.'
                : 'No outings found in this category.',
            actionLabel: status == 'active' ? 'Create Outing' : null,
            onActionPressed: status == 'active'
                ? () => context.push('/split/create')
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final outing = filtered[index];
            return _OutingListItem(
              outing: outing,
              onTap: () => context.push('/split/${outing.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading outings: $err')),
    );
  }
}

class _OutingListItem extends ConsumerWidget {
  final GroupOutingEntry outing;
  final VoidCallback onTap;

  const _OutingListItem({required this.outing, required this.onTap});

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(outingSummaryStreamProvider(outing.id));

    return summaryAsync.when(
      data: (summary) {
        final memberCount = summary?.memberCount ?? 1;
        final spentMinor = summary?.totalSpentMinor ?? 0;

        return InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardSurface
                  : AppColors.lightCardSurface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        outing.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primaryIndigo,
                    ),
                  ],
                ),
                if (outing.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    outing.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$memberCount friends • ${_formatAmount(spentMinor)} spent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                    Text(
                      'Budget: ${_formatAmount(outing.budgetMinor)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
