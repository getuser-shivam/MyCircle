import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Widget? child;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey.withOpacity(0.3),
      highlightColor: highlightColor ?? Colors.white.withOpacity(0.5),
      child: child ?? Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class MediaCardShimmer extends StatelessWidget {
  final double aspectRatio;

  const MediaCardShimmer({
    super.key,
    this.aspectRatio = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ShimmerWidget(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        ShimmerWidget(
          width: double.infinity,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        ShimmerWidget(
          width: 100,
          height: 10,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class UserCardShimmer extends StatelessWidget {
  const UserCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShimmerWidget(
          width: 48,
          height: 48,
          borderRadius: BorderRadius.circular(24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget(
                width: 120,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              ShimmerWidget(
                width: 80,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryChipShimmer extends StatelessWidget {
  const CategoryChipShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ShimmerWidget(
        width: 80,
        height: 32,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
