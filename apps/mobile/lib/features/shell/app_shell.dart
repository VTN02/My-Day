import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_providers.dart';
import '../../core/services/update_service.dart';
import '../../core/widgets/custom_bottom_navigation.dart';

/// AppShell hosting the persistent bottom navigation, branch routing,
/// and automated on-launch app update detection.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _updateTimer;

  static const List<BottomNavItem> _navItems = [
    BottomNavItem(
      label: 'Today',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
    ),
    BottomNavItem(
      label: 'Tasks',
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
    ),
    BottomNavItem(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    BottomNavItem(
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    BottomNavItem(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      activeIcon: Icons.sticky_note_2_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _checkAutoUpdate() {
    // Brief delay to allow initial layout and splash to settle smoothly
    _updateTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      try {
        final settingsRepo = ref.read(settingsRepositoryProvider);
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final lastPromptDate =
            await settingsRepo.getSetting('last_update_prompt_date');
        final lastPromptVersion =
            await settingsRepo.getSetting('last_update_prompt_version');

        final updateService = ref.read(updateServiceProvider);
        final result = await updateService.checkForUpdates();
        if (mounted) {
          ref.read(appUpdateCheckResultProvider.notifier).set(result);
        }

        if (result.status == UpdateStatus.updateAvailable &&
            result.updateInfo != null &&
            mounted) {
          final isMandatory = result.updateInfo!.isMandatory;
          final isNewDay = lastPromptDate != todayKey;
          final isNewerVersionThanPrompted =
              lastPromptVersion != result.updateInfo!.latestVersion;

          // Display update sheet only ONCE per day (or if a brand-new release is published or mandatory)
          if (isMandatory || isNewDay || isNewerVersionThanPrompted) {
            await settingsRepo.setSetting('last_update_prompt_date', todayKey);
            await settingsRepo.setSetting(
              'last_update_prompt_version',
              result.updateInfo!.latestVersion,
            );

            if (mounted) {
              UpdateService.showUpdateSheet(
                context: context,
                info: result.updateInfo!,
                installedVersion: result.installedVersion,
              );
            }
          }
        }
      } catch (_) {
        // Ignore background network/silently
      }
    });
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }
}
