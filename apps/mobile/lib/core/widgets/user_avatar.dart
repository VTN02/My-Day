import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable User Avatar widget that renders custom DPs, monogram presets, or icons.
class UserAvatar extends StatelessWidget {
  final String? avatarPath;
  final String displayName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.displayName,
    this.size = 80,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent = _buildContent();

    if (onTap != null) {
      avatarContent = GestureDetector(onTap: onTap, child: avatarContent);
    }

    if (!showEditBadge) return avatarContent;

    return Stack(
      children: [
        avatarContent,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final path = avatarPath ?? '';

    if (path == 'logo' || path.startsWith('asset:')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: const DecorationImage(
            image: AssetImage('assets/images/app_logo.png'),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: AppColors.primaryIndigo, width: 2),
        ),
      );
    }

    if (path.startsWith('icon:')) {
      final iconKey = path.substring(5);
      final (icon, color) = _resolveIcon(iconKey);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );
    }

    if (path.startsWith('gradient:')) {
      final colorKey = path.substring(9);
      final gradient = _resolveGradient(colorKey);
      final initial = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : 'U';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    // Default: Initial monogram with indigo theme
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryIndigo, AppColors.secondaryViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primaryIndigo.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  (IconData, Color) _resolveIcon(String key) {
    switch (key) {
      case 'developer':
        return (Icons.code_rounded, AppColors.primaryIndigo);
      case 'designer':
        return (Icons.palette_rounded, AppColors.secondaryViolet);
      case 'fitness':
        return (Icons.fitness_center_rounded, AppColors.successMint);
      case 'mind':
        return (Icons.self_improvement_rounded, AppColors.accentCyan);
      case 'rocket':
        return (Icons.rocket_launch_rounded, AppColors.errorCoral);
      case 'star':
        return (Icons.star_rounded, AppColors.warningAmber);
      default:
        return (Icons.person_rounded, AppColors.primaryIndigo);
    }
  }

  LinearGradient _resolveGradient(String key) {
    switch (key) {
      case 'violet':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
        );
      case 'teal':
        return const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
        );
      case 'amber':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        );
      case 'coral':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDB2777)],
        );
      case 'indigo':
      default:
        return const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        );
    }
  }
}
