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
              color: AppGradients.primaryBrand.colors.first.withValues(
                alpha: 0.25,
              ),
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
                children: [leading!, ?trailing],
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

/// Collapsible Sliver Gradient Header matching modern mobile OS standards.
/// When scrolling, it collapses to a compact pinned bar displaying ONLY the header heading.
class SliverGradientHeader extends StatelessWidget {
  final Widget? leading;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottomChild;
  final LinearGradient gradient;
  final double? expandedHeight;
  final double collapsedHeight;

  const SliverGradientHeader({
    super.key,
    this.leading,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomChild,
    this.gradient = AppGradients.primaryBrand,
    this.expandedHeight,
    this.collapsedHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final defaultExpandedHeight = bottomChild != null
        ? (topInset > 0 ? 210.0 : 190.0)
        : (subtitle != null ? (topInset > 0 ? 165.0 : 145.0) : 130.0);
    final calculatedExpandedHeight =
        (expandedHeight ?? defaultExpandedHeight) + topInset;
    final calculatedCollapsedHeight = collapsedHeight + topInset;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverGradientHeaderDelegate(
        leading: leading,
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        bottomChild: bottomChild,
        gradient: gradient,
        topInset: topInset,
        expandedHeight: calculatedExpandedHeight.clamp(
          calculatedCollapsedHeight + 20.0,
          400.0,
        ),
        collapsedHeight: calculatedCollapsedHeight,
      ),
    );
  }
}

class _SliverGradientHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget? leading;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottomChild;
  final LinearGradient gradient;
  final double topInset;
  final double expandedHeight;
  final double collapsedHeight;

  _SliverGradientHeaderDelegate({
    required this.leading,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.bottomChild,
    required this.gradient,
    required this.topInset,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final shrinkProgress = range > 0
        ? (shrinkOffset / range).clamp(0.0, 1.0)
        : 1.0;

    // Fade out expanded elements as user scrolls
    final expandedOpacity = (1.0 - shrinkProgress * 1.8).clamp(0.0, 1.0);
    final bottomOpacity = (1.0 - shrinkProgress * 2.4).clamp(0.0, 1.0);
    // Collapsed header heading fades in as header shrinks
    final collapsedTitleOpacity =
        ((shrinkProgress - 0.4) / 0.6).clamp(0.0, 1.0);

    // Corner radius flattens as it becomes a pinned top navigation bar
    final cornerRadius = 24.0 * (1.0 - shrinkProgress);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(cornerRadius),
            bottomRight: Radius.circular(cornerRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(
                alpha: shrinkProgress > 0.1 ? 0.35 : 0.2,
              ),
              blurRadius: shrinkProgress > 0.1 ? 12 : 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Expanded Header Content (Fades out when scrolling)
            if (expandedOpacity > 0.01)
              Positioned(
                top: topInset + (leading != null ? 52.0 : 12.0),
                left: 20,
                right: 20,
                bottom: 14,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Eyebrow pill
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
                      const SizedBox(height: 8),
                      // Large expanded title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (bottomChild != null && bottomOpacity > 0.01) ...[
                        const Spacer(),
                        Opacity(
                          opacity: bottomOpacity,
                          child: bottomChild!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 2. Compact Top Bar with Header Heading (Always pinned at top)
            Positioned(
              top: topInset,
              left: 12,
              right: 12,
              height: minExtent - topInset,
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else
                    const SizedBox(width: 8),

                  // Header Heading - Only visible when scrolling down
                  Expanded(
                    child: Opacity(
                      opacity: collapsedTitleOpacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Trailing Action Buttons
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverGradientHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.eyebrow != eyebrow ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.topInset != topInset ||
        oldDelegate.leading != leading ||
        oldDelegate.trailing != trailing ||
        oldDelegate.bottomChild != bottomChild ||
        oldDelegate.gradient != gradient;
  }
}
