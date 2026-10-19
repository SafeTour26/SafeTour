import 'package:flutter/material.dart';

/// Design tokens from Prompts/design.md
class AppColors {
  // Surfaces & Tonal Layers
  static const Color surface = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow =
      Color(0xFF1C1B1B); // Primary card containers
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);

  // Text & Outlines
  static const Color onSurface = Color(0xFFE5E2E1); // Primary text
  static const Color onSurfaceVariant = Color(0xFFC2C6D4); // Secondary text
  static const Color outline = Color(0xFF8C909E);
  static const Color outlineVariant = Color(0xFF424752); // Subtle 1px borders

  // Accents - Primary (Muted Action Blue)
  static const Color primary = Color(0xFFADC6FF);
  static const Color onPrimary = Color(0xFF002E69);
  static const Color primaryContainer = Color(0xFF5E92F3);
  static const Color onPrimaryContainer = Color(0xFF002A62);

  // Accents - Secondary (Calm Emerald / Safe status)
  static const Color secondary = Color(0xFF75DAA8);
  static const Color onSecondary = Color(0xFF003823);
  static const Color secondaryContainer = Color(0xFF008056);
  static const Color onSecondaryContainer = Color(0xFFD1FFE3);

  // Accents - Tertiary (Warm Amber / Caution status)
  static const Color tertiary = Color(0xFFE7C268);
  static const Color onTertiary = Color(0xFF3E2E00);
  static const Color tertiaryContainer = Color(0xFFB1903C);
  static const Color onTertiaryContainer = Color(0xFF3A2A00);

  // Accents - Error / SOS (Subtle Coral)
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Input & Component Backgrounds
  static const Color inputBackground = Color(0xFF242424);
  static const Color glassBackground =
      Color(0xD90E0E0E); // 85% opacity of #0E0E0E
  static const Color divider = Color(0x33424752); // 20% opacity border
  static const Color darkGreenCard = Color(0xFF14231B);
  static const Color darkAmberCard = Color(0xFF251D0D);
}
