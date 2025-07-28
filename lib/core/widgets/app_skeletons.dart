import 'package:flutter/material.dart';
import 'package:phcl_accounts/core/widgets/skeleton_widgets.dart';

/// Skeleton for list items
class SkeletonListItem extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final int subtitleLines;

  const SkeletonListItem({
    super.key,
    this.hasLeading = false,
    this.hasTrailing = false,
    this.subtitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonCircle(size: 40),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(height: 16),
                if (subtitleLines > 0) ...[
                  const SizedBox(height: 8),
                  SkeletonText(
                    height: 14,
                    lines: subtitleLines,
                    width: 200,
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            SkeletonWidget(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for transaction list items
class SkeletonTransactionItem extends StatelessWidget {
  const SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SkeletonCircle(size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonText(height: 16),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonText(width: 80, height: 12),
                    const SizedBox(width: 16),
                    SkeletonText(width: 60, height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonText(width: 80, height: 16),
              const SizedBox(height: 4),
              SkeletonText(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for user profile
class SkeletonUserProfile extends StatelessWidget {
  const SkeletonUserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonCircle(size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(width: 120, height: 18),
              const SizedBox(height: 8),
              SkeletonText(width: 160, height: 14),
              const SizedBox(height: 4),
              SkeletonText(width: 100, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for form fields
class SkeletonFormField extends StatelessWidget {
  final bool hasLabel;
  final double height;

  const SkeletonFormField({
    super.key,
    this.hasLabel = true,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          SkeletonText(width: 80, height: 14),
          const SizedBox(height: 8),
        ],
        SkeletonWidget(
          width: double.infinity,
          height: height,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

/// Skeleton for buttons
class SkeletonButton extends StatelessWidget {
  final double? width;
  final double height;
  final bool isRounded;

  const SkeletonButton({
    super.key,
    this.width,
    this.height = 48,
    this.isRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonWidget(
      width: width ?? double.infinity,
      height: height,
      borderRadius: BorderRadius.circular(isRounded ? 24 : 8),
    );
  }
}

/// Skeleton for navigation tabs
class SkeletonNavigationTabs extends StatelessWidget {
  final int tabCount;

  const SkeletonNavigationTabs({
    super.key,
    this.tabCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabCount, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < tabCount - 1 ? 8 : 0,
            ),
            child: SkeletonWidget(
              width: double.infinity,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }
}

/// Skeleton for grid items
class SkeletonGridItem extends StatelessWidget {
  final double aspectRatio;

  const SkeletonGridItem({
    super.key,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: SkeletonCard(
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SkeletonWidget(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonText(height: 14),
            const SizedBox(height: 8),
            SkeletonText(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}
