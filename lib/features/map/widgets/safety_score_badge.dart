import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/score_calculator.dart';

class SafetyScoreBadge extends StatelessWidget {
  final double score;
  final bool showLabel;
  final double size;

  const SafetyScoreBadge({
    super.key,
    required this.score,
    this.showLabel = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final color = ScoreCalculator.getScoreColor(score);
    final bgColor = ScoreCalculator.getScoreContainerColor(score);
    final label = ScoreCalculator.getStatusLabel(score);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.75,
        vertical: size * 0.35,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: size * 0.4),
          Text(
            score.toStringAsFixed(1),
            style: AppTypography.labelMd.copyWith(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: size * 0.4),
            Text(
              '• $label',
              style: AppTypography.labelSm.copyWith(
                fontSize: size * 0.85,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
