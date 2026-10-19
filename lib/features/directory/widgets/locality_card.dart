import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/safety_zone.dart';
import '../../map/widgets/safety_score_badge.dart';

class LocalityCard extends StatelessWidget {
  final SafetyZone zone;
  final double? distanceMeters;
  final VoidCallback onTap;

  const LocalityCard({
    super.key,
    required this.zone,
    this.distanceMeters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding:
              const EdgeInsets.all(24.0), // 24px internal padding per design.md
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title, Distance & Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.areaName,
                          style: AppTypography.headlineSm.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          distanceMeters != null
                              ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km away • ${zone.radiusMeters}m radius'
                              : 'Bengaluru Urban • ${zone.radiusMeters}m radius',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SafetyScoreBadge(
                    score: zone.overallScore,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric Chips Row
              Row(
                children: [
                  _ScoreChip(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Day: ${zone.dayScore.toStringAsFixed(1)}',
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 8),
                  _ScoreChip(
                    icon: Icons.nightlight_round,
                    label: 'Night: ${zone.nightScore.toStringAsFixed(1)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _ScoreChip(
                    icon: Icons.lightbulb_rounded,
                    label: 'Light: ${zone.lightingRating}/10',
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Safety tips preview
              if (zone.safetyTips.isNotEmpty)
                Text(
                  zone.safetyTips,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ScoreChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
