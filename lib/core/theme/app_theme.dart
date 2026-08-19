import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Fábrica dos temas Material 3 do Elytron Dash2Board.
///
/// Decisões deliberadas:
/// * Somente classes de tema com sufixo `...ThemeData` são passadas para
///   [ThemeData]. Isso evita 100% das deprecations recentes do Flutter
///   (`CardTheme` -> `CardThemeData`, `DialogTheme` -> `DialogThemeData`, etc.).
/// * Nenhum uso de `Color.withOpacity` - somente `Color.withValues(alpha: ...)`.
/// * `ColorScheme` é declarado explicitamente (sem `fromSeed`) porque as cores
///   de severidade precisam ser estáveis entre builds e plataformas.
abstract final class AppTheme {
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandGreen,
      onPrimary: Color(0xFF00281A),
      primaryContainer: Color(0xFF00563A),
      onPrimaryContainer: Color(0xFFB8FFE0),
      secondary: AppColors.brandCyan,
      onSecondary: Color(0xFF00242C),
      secondaryContainer: Color(0xFF004E5E),
      onSecondaryContainer: Color(0xFFC2F3FF),
      tertiary: AppColors.brandViolet,
      onTertiary: Color(0xFF1E1136),
      tertiaryContainer: Color(0xFF3E2A6B),
      onTertiaryContainer: Color(0xFFE7DBFF),
      error: AppColors.severityCritical,
      onError: Color(0xFF3B0009),
      errorContainer: Color(0xFF7A0F1C),
      onErrorContainer: Color(0xFFFFDADC),
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: Color(0xFF04070C),
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceElevated,
      surfaceContainerHigh: AppColors.darkSurfaceHighest,
      surfaceContainerHighest: Color(0xFF243141),
      outline: AppColors.darkOutline,
      outlineVariant: Color(0xFF1A2431),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.lightBackground,
      onInverseSurface: AppColors.lightTextPrimary,
      inversePrimary: AppColors.brandGreenDim,
    );

    return _build(
      scheme: scheme,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
    );
  }

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brandGreenDim,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFB8FFE0),
      onPrimaryContainer: Color(0xFF00281A),
      secondary: Color(0xFF0E7C93),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFC2F3FF),
      onSecondaryContainer: Color(0xFF00242C),
      tertiary: Color(0xFF6A45D6),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE7DBFF),
      onTertiaryContainer: Color(0xFF1E1136),
      error: Color(0xFFC1121F),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDADC),
      onErrorContainer: Color(0xFF3B0009),
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurfaceElevated,
      surfaceContainerHigh: AppColors.lightSurfaceHighest,
      surfaceContainerHighest: Color(0xFFD7DEE8),
      outline: AppColors.lightOutline,
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkTextPrimary,
      inversePrimary: AppColors.brandGreen,
    );

    return _build(
      scheme: scheme,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final TextTheme textTheme = AppTypography.scale(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        actionTextColor: scheme.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size.fromHeight(52)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
          backgroundColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.12);
            }
            return scheme.primary;
          }),
          foregroundColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.38);
            }
            return scheme.onPrimary;
          }),
          overlayColor: WidgetStatePropertyAll<Color>(
            scheme.onPrimary.withValues(alpha: 0.10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size.fromHeight(52)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
          foregroundColor: WidgetStatePropertyAll<Color>(scheme.onSurface),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: scheme.outline),
          ),
          overlayColor: WidgetStatePropertyAll<Color>(
            scheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
          foregroundColor: WidgetStatePropertyAll<Color>(scheme.primary),
          overlayColor: WidgetStatePropertyAll<Color>(
            scheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      // NÃO configure `pageTransitionsTheme` aqui.
      // Os builders de transição (`CupertinoPageTransitionsBuilder`,
      // `FadeUpwardsPageTransitionsBuilder`, ...) mudam de nome e de biblioteca
      // entre versões do Flutter e são a fonte mais comum de erro de
      // compilação neste ponto do tema. O padrão do Material 3 já entrega a
      // transição correta por plataforma: deslize lateral no iOS e
      // fade+scale no Android.
    );
  }

  /// Estilo de overlay do sistema para a tela de boas-vindas (edge-to-edge).
  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: AppColors.darkBackground,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: AppColors.lightBackground,
            systemNavigationBarIconBrightness: Brightness.dark,
          );
  }
}
