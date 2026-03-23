import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../theme/app_theme.dart';
import '../widgets/score_ring.dart';
import '../widgets/risk_badge.dart';
import '../widgets/red_flag_card.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final riskColor = AppColors.riskColor(result.riskLevel);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 56,
            title: Text(
              '${result.riskLevel[0].toUpperCase()}${result.riskLevel.substring(1)} Risk',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 22),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(
                      ClipboardData(text: result.toShareText()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analysis copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copy',
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 22),
                onPressed: () => _shareAnalysis(context),
                tooltip: 'Share',
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Score Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          riskColor.withValues(alpha: 0.08),
                          colorScheme.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Hero(
                          tag: 'score_ring_${result.manipulationScore}',
                          child: ScoreRing(
                            score: result.manipulationScore,
                            size: 200,
                            strokeWidth: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        RiskBadge(riskLevel: result.riskLevel, large: true),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // Summary Card
                  _SectionCard(
                    delay: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote_rounded,
                                color: colorScheme.primary, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          result.summary,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.7,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Key Points
                  if (result.keyPoints.isNotEmpty)
                    _SectionCard(
                      delay: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.key_rounded,
                                  color: colorScheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Key Points',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(result.keyPoints.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        result.keyPoints[i],
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  if (result.keyPoints.isNotEmpty) const SizedBox(height: 16),

                  // Red Flags
                  if (result.flags.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded,
                              color: AppColors.riskColor('danger'), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Red Flags (${result.flags.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),
                    ...result.flags.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RedFlagCard(
                              flag: entry.value,
                              index: entry.key,
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  delay: (450 + entry.key * 80).ms,
                                  duration: 400.ms)
                              .slideY(begin: 0.05, end: 0),
                        ),
                    const SizedBox(height: 4),
                  ],

                  // Hidden Meanings
                  if (result.hiddenMeanings.isNotEmpty)
                    _SectionCard(
                      delay: 550,
                      outlined: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility_rounded,
                                  color: colorScheme.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Hidden Meanings',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...result.hiddenMeanings.map(
                            (meaning) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text('\u{1F441}\u{FE0F}',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      meaning,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (result.hiddenMeanings.isNotEmpty)
                    const SizedBox(height: 16),

                  // Tone Analysis
                  if (result.toneAnalysis.isNotEmpty)
                    _SectionCard(
                      delay: 600,
                      compact: true,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.record_voice_over_rounded,
                                color: colorScheme.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tone Analysis',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  result.toneAnalysis,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (result.toneAnalysis.isNotEmpty)
                    const SizedBox(height: 16),

                  // Suggested Response
                  if (result.suggestedResponse.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF0D9488),
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_rounded,
                                  color: const Color(0xFF0D9488), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Suggested Response',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy_rounded,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Clipboard.setData(ClipboardData(
                                      text: result.suggestedResponse));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Suggested response copied!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy response',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.suggestedResponse,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(
                                ClipboardData(text: result.toShareText()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Analysis copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _shareAnalysis(context),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms),

                  // Safe celebration
                  if (result.riskLevel.toLowerCase() == 'safe') ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.riskColor('safe')
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.riskColor('safe')
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('\u{1F389}',
                                style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              'Looking good! This text is safe.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.riskColor('safe'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 600.ms)
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareAnalysis(BuildContext context) {
    HapticFeedback.mediumImpact();
    Share.share(result.toShareText(), subject: 'Contextify Analysis');
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final int delay;
  final bool outlined;
  final bool compact;

  const _SectionCard({
    required this.child,
    required this.delay,
    this.outlined = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: outlined
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}
