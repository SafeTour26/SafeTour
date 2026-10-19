import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/safety_zone.dart';
import 'safety_score_badge.dart';

class LocalityBottomSheet extends StatelessWidget {
  final SafetyZone zone;
  final VoidCallback? onFocusOnMap;

  const LocalityBottomSheet({
    super.key,
    required this.zone,
    this.onFocusOnMap,
  });

  static Future<void> show(BuildContext context, SafetyZone zone,
      {VoidCallback? onFocusOnMap}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocalityBottomSheet(
        zone: zone,
        onFocusOnMap: onFocusOnMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab Handle (40px x 4px)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Area Name & Score Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone.areaName,
                              style: AppTypography.headlineMd,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bengaluru Urban • ${zone.radiusMeters}m Zone Radius',
                              style: AppTypography.bodySm,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SafetyScoreBadge(
                        score: zone.overallScore,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4 Metrics Grid (Day, Night, Crowd, Lighting)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.wb_sunny_rounded,
                          iconColor: AppColors.tertiary,
                          title: 'Day Score',
                          value: '${zone.dayScore.toStringAsFixed(1)} / 10',
                          subtext: 'Transit & Footfall',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.nightlight_round,
                          iconColor: AppColors.primary,
                          title: 'Night Score',
                          value: '${zone.nightScore.toStringAsFixed(1)} / 10',
                          subtext: 'Lighting & Safety',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.groups_rounded,
                          iconColor: AppColors.secondary,
                          title: 'Crowd Density',
                          value: '${zone.crowdRating} / 10',
                          subtext: zone.crowdRating >= 8
                              ? 'Very High Footfall'
                              : zone.crowdRating >= 5
                                  ? 'Moderate Density'
                                  : 'Quiet / Sparse',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.lightbulb_rounded,
                          iconColor: AppColors.tertiary,
                          title: 'Street Lighting',
                          value: '${zone.lightingRating} / 10',
                          subtext: zone.lightingRating >= 8
                              ? 'Well Illuminated'
                              : zone.lightingRating >= 6
                                  ? 'Adequate Stretches'
                                  : 'Dim / Patchy',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Safety Tips Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Newcomer Safety Tips',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          zone.safetyTips.isNotEmpty
                              ? zone.safetyTips
                              : 'Stay on illuminated main streets and prefer app-based cabs after 10 PM.',
                          style: AppTypography.bodyMd.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      if (onFocusOnMap != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onFocusOnMap!();
                            },
                            icon: const Icon(Icons.explore_rounded),
                            label: const Text('View on Map'),
                          ),
                        ),
                      if (onFocusOnMap != null) const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtext;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
