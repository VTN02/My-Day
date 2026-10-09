import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';

/// User Profile Screen connected to Drift repository.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _orgController;
  String? _selectedAvatarPath;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _orgController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Profile Picture (DP)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'MyDay Monogram Logo',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedAvatarPath = 'logo');
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAvatarPath == 'logo'
                          ? AppColors.primaryIndigo
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _selectedAvatarPath == 'logo' ? 2 : 1,
                    ),
                    borderRadius: AppRadius.mdRadius,
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  ),
                  child: const Row(
                    children: [
                      UserAvatar(
                        avatarPath: 'logo',
                        displayName: 'MyDay',
                        size: 44,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Glossy Gradient MD Logo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              'Official MyDay Monogram Icon',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gradient Monograms',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  'indigo',
                  'violet',
                  'teal',
                  'amber',
                  'coral',
                ].map((g) {
                  final key = 'gradient:$g';
                  final isSel = _selectedAvatarPath == key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarPath = key);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? AppColors.primaryIndigo : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: UserAvatar(
                        avatarPath: key,
                        displayName: _nameController.text,
                        size: 42,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Persona Icons',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  'developer',
                  'designer',
                  'fitness',
                  'mind',
                  'rocket',
                  'star',
                ].map((iconKey) {
                  final key = 'icon:$iconKey';
                  final isSel = _selectedAvatarPath == key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarPath = key);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? AppColors.primaryIndigo : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: UserAvatar(
                        avatarPath: key,
                        displayName: _nameController.text,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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

    profileAsync.whenData((profile) {
      if (!_isInitialized && profile != null) {
        _nameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        _orgController.text = profile.organization ?? '';
        _selectedAvatarPath = profile.avatarPath;
        _isInitialized = true;
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Personal Identity',
              title: 'User Profile',
              subtitle:
                  'Your personal data stays 100% on this device in SQLite',
              trailing: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: UserAvatar(
                    avatarPath: _selectedAvatarPath,
                    displayName: _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'User',
                    size: 92,
                    showEditBadge: true,
                    onTap: _showAvatarPicker,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Display Name',
                        hint: 'Your name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Work / Organization',
                        hint: 'Company or university',
                        controller: _orgController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Bio / Focus Statement',
                        hint: 'Short bio',
                        maxLines: 3,
                        controller: _bioController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Changes',
                  isFullWidth: true,
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;

                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfile(
                          displayName: name,
                          bio: _bioController.text.trim(),
                          organization: _orgController.text.trim(),
                          avatarPath: _selectedAvatarPath,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile saved to local SQLite database',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
