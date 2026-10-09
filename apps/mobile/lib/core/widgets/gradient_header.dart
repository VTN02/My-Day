import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';

/// Premium edge-to-edge gradient banner header matching modern mobile OS standards.
class GradientHeader extends StatelessWidget {
  final Widget? leading;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottomChild;
  final LinearGradient gradient;

  const GradientHeader({
    super.key,
    this.leading,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomChild,
    this.gradient = AppGradients.primaryBrand,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final effectiveTopPadding = topInset > 0 ? topInset + 10 : 26.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppGradients.primaryBrand.colors.first.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, effectiveTopPadding, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Navigation & Action Row
            if (leading != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leading!,
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Main Header Information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 14,
                                height: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              eyebrow.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (leading == null && trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),

            if (bottomChild != null) ...[
              const SizedBox(height: 18),
              bottomChild!,
            ],
          ],
        ),
      ),
    );
  }
}
