import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/services/smart_reminder_service.dart';
import 'package:mobile/core/services/tune_manager_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/loading_state.dart';

/// Screen for configuring user Smart Reminder Escalation and selecting notification tunes.
class SmartReminderSettingsScreen extends ConsumerStatefulWidget {
  const SmartReminderSettingsScreen({super.key});

  @override
  ConsumerState<SmartReminderSettingsScreen> createState() =>
      _SmartReminderSettingsScreenState();
}

class _SmartReminderSettingsScreenState
    extends ConsumerState<SmartReminderSettingsScreen> {
  bool _escalationEnabled = true;
  int _defaultDelayMinutes = 10;
  int _defaultMaxRepeats = 2;
  String _selectedTuneId = 'tune_system_default';

  bool _isLoading = true;
  String? _currentlyPlayingTuneId;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final enabled =
        await settingsRepo.getSetting('smart_reminders_enabled') ?? 'true';
    final delay =
        await settingsRepo.getSetting('smart_reminders_default_delay') ?? '10';
    final repeats =
        await settingsRepo.getSetting('smart_reminders_default_repeats') ?? '2';
    final tune =
        await settingsRepo.getSetting('smart_reminders_selected_tune') ??
            'tune_system_default';
    if (mounted) {
      setState(() {
        _escalationEnabled = enabled == 'true';
        _defaultDelayMinutes = int.tryParse(delay) ?? 10;
        _defaultMaxRepeats = int.tryParse(repeats) ?? 2;
        _selectedTuneId = tune;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    await ref.read(settingsRepositoryProvider).setSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tunesAsync = ref.watch(availableTunesProvider);
    final tuneManager = ref.watch(tuneManagerServiceProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Smart Reminders & Tunes'),
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Follow-up Escalation Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notification_important_rounded,
                          color: AppColors.primaryIndigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Follow-up Reminders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Repeat notification if a task remains incomplete after due time',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _escalationEnabled,
                        activeThumbColor: AppColors.primaryIndigo,
                        onChanged: (val) {
                          setState(() => _escalationEnabled = val);
                          _saveSetting(
                            'smart_reminders_enabled',
                            val ? 'true' : 'false',
                          );
                        },
                      ),
                    ],
                  ),
                  if (_escalationEnabled) ...[
                    const Divider(height: 28),

                    // Interval Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Follow-up Delay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _defaultDelayMinutes,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 minutes')),
                            DropdownMenuItem(value: 10, child: Text('10 minutes')),
                            DropdownMenuItem(value: 15, child: Text('15 minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 minutes')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _defaultDelayMinutes = val);
                              _saveSetting(
                                'smart_reminders_default_delay',
                                val.toString(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Max Repeats Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maximum Follow-ups',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _defaultMaxRepeats,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 time')),
                            DropdownMenuItem(value: 2, child: Text('2 times')),
                            DropdownMenuItem(value: 3, child: Text('3 times')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _defaultMaxRepeats = val);
                              _saveSetting(
                                'smart_reminders_default_repeats',
                                val.toString(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Reminder Melody Catalog Section
            Text(
              'Notification Melody Catalog',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Curated tunes managed through Super Admin, cached offline for reliability.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 12),

            tunesAsync.when(
              data: (tunes) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tunes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tune = tunes[index];
                    final isSelected = _selectedTuneId == tune.id;
                    final isPlaying = _currentlyPlayingTuneId == tune.id;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkCardSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryIndigo
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Play / Pause Preview Button
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 32,
                              color: AppColors.primaryIndigo,
                            ),
                            onPressed: () async {
                              if (isPlaying) {
                                await tuneManager.stopPreview();
                                setState(() => _currentlyPlayingTuneId = null);
                              } else {
                                setState(() => _currentlyPlayingTuneId = tune.id);
                                await tuneManager.playPreview(
                                  tune,
                                  onComplete: () {
                                    if (mounted) {
                                      setState(() => _currentlyPlayingTuneId = null);
                                    }
                                  },
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          // Tune Title & Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tune.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.darkPrimaryText
                                              : AppColors.lightPrimaryText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (tune.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Default',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (tune.description != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    tune.description!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Radio Selector
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: tune.id,
                            // ignore: deprecated_member_use
                            groupValue: _selectedTuneId,
                            activeColor: AppColors.primaryIndigo,
                            // ignore: deprecated_member_use
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _selectedTuneId = val);
                                await _saveSetting(
                                  'smart_reminders_selected_tune',
                                  val,
                                );
                                // Cache if remote
                                if (!tune.isLocal && !tune.isCached) {
                                  await tuneManager.downloadAndCacheTune(tune);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => Center(child: Text('Error loading tunes: $e')),
            ),
            const SizedBox(height: 24),

            // 3. Test Notification Action
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alarm_on_rounded),
                label: const Text('Send Test Smart Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await ref
                      .read(smartReminderServiceProvider)
                      .scheduleTaskWithEscalation(
                        TaskEntry(
                          id: 'test_task_esc',
                          title: 'Test Smart Reminder Escalation',
                          category: 'Work',
                          priority: 'high',
                          dueDate: DateTime.now().add(const Duration(seconds: 4)),
                          dueTime: null,
                          reminder: 'once',
                          isCompleted: false,
                          followUpEnabled: _escalationEnabled,
                          followUpDelayMinutes: 1, // 1 min for testing
                          maxRepeats: _defaultMaxRepeats,
                          selectedTuneId: _selectedTuneId,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Test reminder scheduled in 4 seconds with escalation follow-ups!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
