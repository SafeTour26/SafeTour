import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScoreCalculator {
  static Color getScoreColor(double score) {
    if (score >= 7.5) {
      return AppColors.secondary; // Calm Emerald
    } else if (score >= 6.0) {
      return AppColors.tertiary; // Warm Amber
    } else {
      return AppColors.error; // Subtle Coral
    }
  }

  static Color getScoreContainerColor(double score) {
    if (score >= 7.5) {
      return const Color(0x3375DAA8); // 20% Emerald
    } else if (score >= 6.0) {
      return const Color(0x33E7C268); // 20% Amber
    } else {
      return const Color(0x33FFB4AB); // 20% Coral
    }
  }

  static Color getMapCircleFillColor(double score) {
    if (score >= 7.5) {
      return const Color(0x2E75DAA8); // ~18% opacity emerald
    } else if (score >= 6.0) {
      return const Color(0x2EE7C268); // ~18% opacity amber
    } else {
      return const Color(0x33FFB4AB); // ~20% opacity coral
    }
  }

  static Color getMapCircleBorderColor(double score) {
    if (score >= 7.5) {
      return AppColors.secondary.withValues(alpha: 0.85);
    } else if (score >= 6.0) {
      return AppColors.tertiary.withValues(alpha: 0.85);
    } else {
      return AppColors.error.withValues(alpha: 0.85);
    }
  }

  static String getStatusLabel(double score) {
    if (score >= 7.5) {
      return 'Safe Zone';
    } else if (score >= 6.0) {
      return 'Moderate Vigilance';
    } else {
      return 'Caution Zone';
    }
  }
}
