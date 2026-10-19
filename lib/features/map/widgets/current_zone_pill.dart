import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/safety_zone.dart';
import 'safety_score_badge.dart';

class CurrentZonePill extends StatelessWidget {
  final SafetyZone? currentZone;
  final double? distanceMeters;
  final VoidCallback? onTap;

  const CurrentZonePill({
    super.key,
    required this.currentZone,
    this.distanceMeters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (currentZone == null) return const SizedBox.shrink();

    final isInside =
        distanceMeters != null && distanceMeters! <= currentZone!.radiusMeters;
    final distanceText = isInside
        ? 'Inside Active Safety Zone'
        : distanceMeters != null
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km to zone center'
            : 'Nearest Safe Zone';

    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          isInside ? AppColors.secondary : AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentZone!.areaName,
                          style: AppTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          distanceText,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SafetyScoreBadge(
                    score: currentZone!.overallScore,
                    showLabel: false,
                    size: 13,
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
