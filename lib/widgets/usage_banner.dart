import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/usage_service.dart';
import 'paywall.dart';

class UsageBanner extends StatelessWidget {
  const UsageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isSignedIn;
    try {
      isSignedIn = AuthService.isSignedIn;
    } catch (e) {
      isSignedIn = false;
    }
    final isProUser = UsageService.isPro();

    // Pro user
    if (isProUser) {
      return _buildProBanner(colorScheme);
    }

    // Signed-in free user
    if (isSignedIn) {
      return _buildSignedInBanner(context, colorScheme);
    }

    // Anonymous user
    return _buildAnonymousBanner(colorScheme);
  }

  Widget _buildProBanner(ColorScheme colorScheme) {
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
          const Text('\u{2B50}', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            'Pro \u2014 Unlimited analyses',
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

  Widget _buildSignedInBanner(BuildContext context, ColorScheme colorScheme) {
    final dailyUses = UsageService.getDailyUses();
    final remaining = UsageService.getRemainingUses(true, false);
    final progress =
        (dailyUses / UsageService.maxDailyFreeUses).clamp(0.0, 1.0);

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
              const Text('\u{1F4CA}', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$remaining of ${UsageService.maxDailyFreeUses} daily uses remaining',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Paywall.show(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\u{2B50}', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Upgrade',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
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

  Widget _buildAnonymousBanner(ColorScheme colorScheme) {
    final totalUses = UsageService.getTotalUses();
    final remaining = UsageService.getRemainingUses(false, false);
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
              const Text('\u{1F513}', style: TextStyle(fontSize: 14)),
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
