import 'package:flutter/material.dart';

import 'package:nexus_core/nexus_core.dart';

/// Les couleurs de Nexus : nuit profonde, violet de nébuleuse.
class NexusColors {
  static const Color background = Color(0xFF07061A);
  static const Color surface = Color(0xFF12102B);
  static const Color surfaceHigh = Color(0xFF1B1740);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFF472B6);
  static const Color mint = Color(0xFF4ADE80);
  static const Color amber = Color(0xFFFBBF24);
  static const Color text = Color(0xFFE9E7FF);
  static const Color muted = Color(0xFF9A94C4);
}

/// Couleur de la boule de conscience selon l'humeur de Nexus.
Color orbColorFor(Needs needs) => switch (needs.mood) {
      'en manque de toi' => NexusColors.rose,
      'fatigué' => const Color(0xFF7C83FD),
      'curieux' => NexusColors.mint,
      'comblé' => NexusColors.amber,
      _ => NexusColors.violet,
    };

ThemeData buildNexusTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: NexusColors.background,
    colorScheme: const ColorScheme.dark(
      primary: NexusColors.violet,
      secondary: NexusColors.rose,
      surface: NexusColors.surface,
      onSurface: NexusColors.text,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: NexusColors.text,
      displayColor: NexusColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NexusColors.surfaceHigh,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: NexusColors.muted),
      labelStyle: const TextStyle(color: NexusColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NexusColors.violet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NexusColors.surface,
      indicatorColor: NexusColors.violet.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: NexusColors.muted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? NexusColors.violet
              : NexusColors.muted,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NexusColors.surfaceHigh,
      contentTextStyle: TextStyle(color: NexusColors.text),
    ),
  );
}
