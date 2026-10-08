import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/section_header.dart';

/// Application Settings Screen Foundation.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'LKR (Rs.)';
  String _selectedTheme = 'System';
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Make It Yours',
              title: 'Settings',
              subtitle: 'Personalize your preferences and data',
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
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
                    subtitle: const Text(
                      'Alex Fernando • Independent Creator',
                      style: TextStyle(fontSize: 12),
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
                          value: _selectedLanguage,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'English',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'Tamil',
                              child: Text('தமிழ் (Tamil)'),
                            ),
                            DropdownMenuItem(
                              value: 'Sinhala',
                              child: Text('සිංහල (Sinhala)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
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
                              value: 'LKR (Rs.)',
                              child: Text('LKR (Rs.)'),
                            ),
                            DropdownMenuItem(
                              value: 'USD (\$)',
                              child: Text('USD (\$)'),
                            ),
                            DropdownMenuItem(
                              value: 'EUR (€)',
                              child: Text('EUR (€)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCurrency = val);
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
                              value: 'System',
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: 'Light',
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: 'Dark',
                              child: Text('Dark'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTheme = val);
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
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),
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
                                'Cloud sync will be available in Milestone 10',
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
                          'Export Local Data (JSON/CSV)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Backup all tasks, notes and finance records',
                          style: TextStyle(fontSize: 11),
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Subtle Tech Community Link
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSoftMint
                                  : AppColors.lightSoftMint,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              color: AppColors.successMint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tech Community',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Join discussions and product feedback on WhatsApp',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'WhatsApp Community invite link will open in external browser',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Join Community'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'MyDay v1.0.0 (Milestone 1 Preview)\nOffline-First Life Management Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
