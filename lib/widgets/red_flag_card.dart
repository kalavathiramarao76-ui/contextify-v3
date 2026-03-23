import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../theme/app_theme.dart';
import 'risk_badge.dart';

class RedFlagCard extends StatelessWidget {
  final RedFlag flag;
  final int index;

  const RedFlagCard({
    super.key,
    required this.flag,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppColors.severityColor(flag.severity);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: severityColor,
              width: 4,
            ),
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            childrenPadding:
                const EdgeInsets.only(left: 18, right: 18, bottom: 18),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SeverityBadge(severity: flag.severity),
                    const SizedBox(width: 8),
                    TypeBadge(type: flag.type),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  flag.reason.length > 60
                      ? '${flag.reason.substring(0, 60)}...'
                      : flag.reason,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: severityColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201C${flag.text}\u201D',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withOpacity(0.75),
                        height: 1.6,
                      ),
                    ),
                    if (flag.reason.length > 60) ...[
                      const SizedBox(height: 12),
                      Text(
                        flag.reason,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
