import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base skeleton widget with shimmer effect
class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor ?? (isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final lineWidth = width ?? (isLast ? 120.0 : double.infinity);
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: SkeletonWidget(
            width: lineWidth,
            height: height,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Skeleton for circular elements (avatars, icons)
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonWidget(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

/// Skeleton for cards
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Widget? child;

  const SkeletonCard({
    super.key,
    this.width,
    required this.height,
    this.padding,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}
