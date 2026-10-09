import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';

/// Application Settings Screen connected to SQLite persistence.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedLanguageCode = 'en';
  String _selectedCurrency = 'LKR';
  String _selectedTheme = 'system';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final lang = await settingsRepo.getSetting('language') ?? 'en';
    final curr = await settingsRepo.getSetting('currency') ?? 'LKR';
    final theme = await settingsRepo.getSetting('theme_mode') ?? 'system';
    final notif =
        await settingsRepo.getSetting('notifications_enabled') ?? 'true';

    if (mounted) {
      setState(() {
        _selectedLanguageCode = lang;
        _selectedCurrency = curr;
        _selectedTheme = theme;
        _notificationsEnabled = notif == 'true';
      });
    }
  }

  bool _isCheckingUpdate = false;

  Future<void> _updateSetting(String key, String value) async {
    await ref.read(settingsRepositoryProvider).setSetting(key, value);
  }

  Future<void> _checkAppUpdates() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final result = await ref.read(updateServiceProvider).checkForUpdates();
      if (!mounted) return;

      setState(() => _isCheckingUpdate = false);

      if (result.status == UpdateStatus.updateAvailable &&
          result.updateInfo != null) {
        UpdateService.showUpdateSheet(
          context: context,
          info: result.updateInfo!,
        );
      } else if (result.status == UpdateStatus.upToDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are on the latest version of MyDay (v${AppVersion.versionName})!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successMint,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Unable to connect to update server.',
            ),
            backgroundColor: AppColors.errorCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for updates: $e'),
            backgroundColor: AppColors.errorCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTestUpdateModal() {
    // Send native mobile system notification outside the app
    NotificationService().showAppUpdateNotification(
      latestVersion: '1.0.1',
      fileSize: '28 MB',
      releaseNotes: const [
        'New Rectangular Calendar with one-tap pop-up modal',
        'Interactive Finance Donut & Cash Flow analysis charts',
        'Full-context Reminder Notifications with Quick Actions',
        'Profile Avatar Picker with custom DPs and gradients',
        'Offline APK OTA Update system integrated',
      ],
    );

    UpdateService.showUpdateSheet(
      context: context,
      info: const AppUpdateInfo(
        latestVersion: '1.0.1',
        versionCode: 2,
        apkDownloadUrl:
            'https://github.com/VTN02/My-Day/releases/download/v1.0.1/myday-v1.0.1.apk',
        releaseDate: 'October 2026',
        fileSize: '28 MB',
        releaseNotes: [
          'New Rectangular Calendar with one-tap pop-up modal',
          'Interactive Finance Donut & Cash Flow analysis charts',
          'Full-context Reminder Notifications with Quick Actions',
          'Profile Avatar Picker with custom DPs and gradients',
          'Offline APK OTA Update system integrated',
        ],
      ),
    );
  }

  void _showExportBackupSheet() async {
    final jsonStr = await ref.read(backupServiceProvider).exportBackupJson();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Export Local Backup (JSON)',
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
              Text(
                'Complete database snapshot including all tasks, notes, finances, and settings.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Copy Backup JSON to Clipboard',
                icon: Icons.copy_rounded,
                isFullWidth: true,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Backup JSON copied to clipboard! Keep it safe.',
                      ),
                      backgroundColor: AppColors.successMint,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRestoreBackupSheet() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                      'Restore from Backup (JSON)',
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
                Text(
                  'Paste your exported MyDay JSON data below to restore your records into SQLite.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Backup JSON',
                  hint: 'Paste JSON content here...',
                  controller: controller,
                  maxLines: 6,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Restore All Records',
                  icon: Icons.restore_rounded,
                  isFullWidth: true,
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;

                    try {
                      final stats = await ref
                          .read(backupServiceProvider)
                          .restoreBackupJson(text);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      await _loadSettings();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Restore successful! Restored ${stats['tasks']} tasks, ${stats['notes']} notes, ${stats['transactions']} transactions.',
                            ),
                            backgroundColor: AppColors.successMint,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to restore backup: $e'),
                            backgroundColor: AppColors.errorCoral,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final profileAsync = ref.watch(userProfileStreamProvider);
    final profile = profileAsync.value;
    final displayName = profile?.displayName ?? 'MyDay User';
    final org = profile?.organization;
    final profileSubtitle = org != null && org.isNotEmpty
        ? '$displayName • $org'
        : (profile?.bio != null && profile!.bio!.isNotEmpty
              ? '$displayName • ${profile.bio}'
              : '$displayName • Tap to edit profile');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context.pop(),
              ),
              eyebrow: 'Make It Yours',
              title: 'Settings',
              subtitle: 'Personalize your preferences and data',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account / Profile Item
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSoftIndigo
                            : AppColors.lightSoftIndigo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryIndigo,
                      ),
                    ),
                    title: const Text(
                      'Profile & Identity',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      profileSubtitle,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile'),
                  ),
                ),

                const SizedBox(height: 16),
                SectionHeader(title: 'Preferences'),

                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // Language
                      ListTile(
                        leading: const Icon(
                          Icons.language,
                          color: AppColors.primaryIndigo,
                        ),
                        title: const Text(
                          'Language',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: _selectedLanguageCode,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ta',
                              child: Text('தமிழ் (Tamil)'),
                            ),
                            DropdownMenuItem(
                              value: 'si',
                              child: Text('සිංහල (Sinhala)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguageCode = val);
                              _updateSetting('language', val);
                            }
                          },
                        ),
                      ),
                      Divider(color: borderColor),
                      // Currency
                      ListTile(
                        leading: const Icon(
                          Icons.monetization_on_outlined,
                          color: AppColors.accentCyan,
                        ),
                        title: const Text(
                          'Default Currency',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: _selectedCurrency,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'LKR',
                              child: Text('LKR (Rs.)'),
                            ),
                            DropdownMenuItem(
                              value: 'USD',
                              child: Text('USD (\$)'),
                            ),
                            DropdownMenuItem(
                              value: 'EUR',
                              child: Text('EUR (€)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCurrency = val);
                              _updateSetting('currency', val);
                            }
                          },
                        ),
                      ),
                      Divider(color: borderColor),
                      // Theme
                      ListTile(
                        leading: const Icon(
                          Icons.dark_mode_outlined,
                          color: AppColors.secondaryViolet,
                        ),
                        title: const Text(
                          'Theme Appearance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: _selectedTheme,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'system',
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: 'light',
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: 'dark',
                              child: Text('Dark'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTheme = val);
                              _updateSetting('theme_mode', val);
                            }
                          },
                        ),
                      ),
                      Divider(color: borderColor),
                      // Notifications
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.successMint,
                        ),
                        title: const Text(
                          'Task & Due Reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        value: _notificationsEnabled,
                        activeTrackColor: AppColors.primaryIndigo,
                        onChanged: (val) {
                          setState(() => _notificationsEnabled = val);
                          _updateSetting(
                            'notifications_enabled',
                            val.toString(),
                          );
                        },
                      ),
                      if (_notificationsEnabled) ...[
                        Divider(color: borderColor),
                        ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.notification_important_rounded,
                            color: AppColors.primaryIndigo,
                            size: 20,
                          ),
                          title: const Text(
                            'Preview Full-Context Reminder',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Shows complete task details without opening the app',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.send_rounded, size: 18),
                          onTap: () {
                            ref
                                .read(reminderServiceProvider)
                                .sendTestReminder(context);
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SectionHeader(title: 'Data & Privacy'),

                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primaryIndigo,
                        ),
                        title: const Text(
                          'Cloud Backup & Sync',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Optional account sync planned for Milestone 10',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cloud sync with Supabase scheduled for Milestone 10',
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(color: borderColor),
                      ListTile(
                        leading: const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.accentCyan,
                        ),
                        title: const Text(
                          'Export Local Backup (JSON)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Generate a JSON backup of all your tasks, notes, finances',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showExportBackupSheet,
                      ),
                      Divider(color: borderColor),
                      ListTile(
                        leading: const Icon(
                          Icons.restore_page_outlined,
                          color: AppColors.secondaryViolet,
                        ),
                        title: const Text(
                          'Restore from Backup (JSON)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Import your exported MyDay data back into SQLite',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showRestoreBackupSheet,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // App Updates & Releases (OTA Direct APK System)
                const SectionHeader(
                  title: 'App Updates & Releases',
                  subtitle: 'Over-The-Air APK updater for direct installations',
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSurface : Colors.white,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryIndigo.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.primaryIndigo,
                              size: 22,
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
                                      'MyDay v${AppVersion.versionName}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successMint.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Direct APK',
                                        style: TextStyle(
                                          color: AppColors.successMint,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Build ${AppVersion.versionCode} • Installed Locally',
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Direct APK updates download over your existing installation. Your local SQLite data, tasks, and settings are 100% preserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCheckingUpdate
                                  ? null
                                  : _checkAppUpdates,
                              icon: _isCheckingUpdate
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                _isCheckingUpdate
                                    ? 'Checking...'
                                    : 'Check for Updates',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryIndigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _showTestUpdateModal,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              foregroundColor: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.buttonRadius,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            child: const Tooltip(
                              message:
                                  'Preview how the update prompt appears to users',
                              child: Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TheVBuilds WhatsApp Community Channel
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                          : [
                              const Color(0xFF25D366).withValues(alpha: 0.12),
                              const Color(0xFF128C7E).withValues(alpha: 0.08),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: const Color(0xFF25D366).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'TheVBuilds Channel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: Color(0xFF25D366),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Follow on WhatsApp for releases, guides, and tips',
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          'Follow TheVBuilds on WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final success =
                              await UpdateService.openWhatsAppCommunity();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open WhatsApp channel link.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App Brand Footer with Glossy Gradient Monogram Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/app_logo.png'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryIndigo.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MyDay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline-First Personal Life Management\nCrafted by TheVBuilds',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
