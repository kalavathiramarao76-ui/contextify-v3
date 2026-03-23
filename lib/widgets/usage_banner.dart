import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/usage_service.dart';

class UsageBanner extends StatelessWidget {
  const UsageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSignedIn;
    try {
      isSignedIn = AuthService.isSignedIn;
    } catch (e) {
      isSignedIn = false;
    }

    if (isSignedIn) {
      return _buildSignedInBanner(colorScheme);
    }

    return _buildAnonymousBanner(colorScheme);
  }

  Widget _buildSignedInBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0D9488).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Text('\u2705', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            'Unlimited analyses',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousBanner(ColorScheme colorScheme) {
    final totalUses = UsageService.getTotalUses();
    final remaining = UsageService.getRemainingFreeUses();
    final progress =
        (totalUses / UsageService.maxFreeUses).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\uD83D\uDD13', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '$remaining of ${UsageService.maxFreeUses} free uses remaining',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: const Color(0xFF0D9488),
              backgroundColor:
                  const Color(0xFF0D9488).withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
