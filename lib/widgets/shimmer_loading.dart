import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerBase = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.4);
    final shimmerHighlight = theme.colorScheme.surfaceContainerHigh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score ring placeholder
        Center(
          child: Column(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shimmerBase,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 28,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Summary card
        _ShimmerCard(height: 120, color: shimmerBase),
        const SizedBox(height: 12),
        // Key points card
        _ShimmerCard(height: 90, color: shimmerBase),
        const SizedBox(height: 12),
        // Red flags card
        _ShimmerCard(height: 140, color: shimmerBase),
        const SizedBox(height: 12),
        // Tone card
        _ShimmerCard(height: 70, color: shimmerBase),
        const SizedBox(height: 12),
        // Suggested response card
        _ShimmerCard(height: 100, color: shimmerBase),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: shimmerHighlight,
        );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  final Color color;

  const _ShimmerCard({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 180,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}
